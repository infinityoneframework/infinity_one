defmodule UccChatWeb.RoomChannel.Message do
  use UccLogger
  use UccChatWeb.Channel.Utils

  import UcxUccWeb.Gettext
  import UcxUccWeb.Utils

  alias UcxUcc.{Accounts, Repo, Permissions}
  alias UccChat.{ChannelService, RobotService, MessageService}
  alias UccChat.{Channel, Message, Attachment, StarredMessage, PinnedMessage}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.MessageService, as: Service
  # alias __MODULE__.Client
  alias Rebel.SweetAlert
  alias UccChatWeb.RoomChannel.MessageCog

  alias UccChatWeb.{MessageView, Client}
  alias UccChatWeb.RoomChannel.Attachment, as: WebAttachment

  require UccChat.ChatConstants, as: CC

  @preloads [:user, :edited_by, :attachments, :reactions]

  def create_attachment(params, socket, client \\ Client) do
    Logger.debug "params: #{inspect params}"
    do_create("", params["channel_id"], params["user_id"], params, socket,
      client, &handle_new_attachment_message/4)
  end

  def create(body, channel_id, user_id, socket, client \\ Client) do
    Logger.debug "body: #{inspect body}"
    do_create(body, channel_id, user_id, %{}, socket,
      client, &handle_new_message/4)
  end

  defp do_create(body, channel_id, user_id, params, socket, client, handler) do
    user = Accounts.get_user user_id
    channel = Channel.get!(channel_id)
    msg_params = if Channel.direct?(channel), do: %{type: "d"}, else: %{}

    cond do
      ChannelService.user_muted? user_id, channel_id ->
        push_private_message socket, channel_id,
        # MessageService.broadcast_private_message(channel_id, user_id,
          ~g"You have been muted and cannot speak in this room", client

        # sys_msg = create_system_message(channel_id,
        #   ~g"You have been muted and cannot speak in this room")
        # html = render_message(sys_msg)
        # push_message(socket, sys_msg.id, user_id, html)
        create_and_push_new_message socket, body, channel_id, user_id, %{type: "p"}, client

        # msg = create_message(message, user_id, channel_id, %{ type: "p", })
        # html = render_message(msg)
        # push_message(socket, msg.id, user_id, html)

      channel.read_only and
        not Permissions.has_permission?(user, "post-readonly", channel_id) ->

        client.toastr socket, :error,
          ~g(You are not authorized to create a message)

      channel.archived ->
        client.toastr socket, :error,
          ~g(You are not authorized to create a message)

      true ->
        handler.(socket, body, [
          channel: channel,
          user: user,
          msg_params: msg_params,
          params: params
        ], client)
    end

    Service.stop_typing(socket, user_id, channel_id)
    socket
  end

  def update(body, _channel_id, user_id, message_id, socket, client \\ Client) do
    assigns = socket.assigns
    user = Accounts.get_user user_id
    channel_id = assigns.channel_id

    value = body
    message = Message.get(message_id, preload: @preloads)
    case message.attachments do
      [] ->
        {mention_body, mentions} = Service.encode_mentions(body, channel_id)

        # TODO: Do we want to pass to the robots again? I can think of
        #       arguments on both sides of this decision. For now, we
        #       won't.

        case Message.update(message, %{body: body, edited_id: user.id}) do
          {:ok, message} ->
            channel = Channel.get channel_id
            Service.update_mentions(mentions, message.id, message.channel_id, mention_body)
            Service.update_direct_notices(channel, message)
            {:ok, message}
          {:error, changeset} ->
            Logger.error inspect(changeset)
        end

      [att|_] ->
        update_attachment_description(att, message, value, user)
    end
    |> case do
      {:ok, message} ->
        message
        |> Repo.preload(MessageService.preloads())
        |> render_message
        |> client.broadcast_update_message(socket)
      _error ->
        client.toastr socket, :error,
          ~g(Problem updating your message)
    end

    MessageService.stop_typing(socket, user_id, channel_id)
  end

  defp handle_new_message(socket, body, opts, client) do
    user = opts[:user]
    channel = opts[:channel]
    channel_id = channel.id

    {mention_body, mentions} = Service.encode_mentions(body, channel_id)

    # TODO: This should be moved to a UccPubSub broadcast.
    # This should be configurable, but for how we will only allow bot
    # processing for public channels

    if channel.type == 0 do
      RobotService.new_message body, channel, user
    end

    message = create_message(body, user.id, channel_id, opts[:msg_params])

    Service.create_mentions(mentions, message.id, message.channel_id, mention_body)
    Service.update_direct_notices(channel, message)

    broadcast_message(socket, message.id, user.id, message, [])

    message
    |> render_message
    |> client.broadcast_message(socket)
  end

  defp handle_new_attachment_message(socket, message_body, opts, client) do
    Logger.debug "message_body: #{inspect message_body}"
    user = opts[:user]
    channel = opts[:channel]
    params = opts[:params]
    channel_id = channel.id

    case WebAttachment.create user.id, channel_id, params do
      {:ok, message} ->
        message = Message.preload_schema(message, [:user, :attachments, :reactions])
        robot_body = "Attachment: #{params["file_name"]}, Type: #{params["type"]}, " <>
          ~s(Description: "#{params["description"]}")

        if channel.type == 0 do
          RobotService.new_message robot_body, channel, user
        end

        Service.update_direct_notices(channel, message)

        broadcast_message(socket, message.id, user.id, message.body, [])

        client.toastr! socket, :success,
          ~g(Attachment posted successfully.)

        message
        |> render_message
        |> client.broadcast_message(socket)

      error ->
        client.toastr! socket, :error,
          ~g(There was a problem creating that attachment.)
        Logger.error "error: " <> inspect(error)
    end

    socket
  end

  def create_system_message(channel_id, body) do
    bot_id = Helpers.get_bot_id()
    create_message(body, bot_id, channel_id,
      %{
        type: "p",
        system: true,
        sequential: false,
      })
  end

  def create_private_message(channel_id, body) do
    bot_id = Helpers.get_bot_id()
    create_message(body, bot_id, channel_id,
      %{
        system: true,
        sequential: false,
      })
  end

  def create_message(body, user_id, channel_id, params \\ %{}) do
    sequential? =
      case Message.last_message(channel_id) do
        nil -> false
        lm ->
          Timex.after?(Timex.shift(lm.inserted_at,
            seconds: UccSettings.grouping_period_seconds()), Timex.now) and
            user_id == lm.user_id
      end

    message =
      Message.create!(Map.merge(
        %{
          sequential: sequential?,
          channel_id: channel_id,
          user_id: user_id,
          body: body
        }, params))
      |> Repo.preload(@preloads)

    if params[:type] == "p" do
      Repo.delete(message)
    else
      Service.embed_link_previews(body, channel_id, message.id)
    end
    message
  end

  def render_message(message) do
    user_id = message.user_id
    user = Accounts.get_user user_id
    message_opts = UccChatWeb.MessageView.message_opts()

    {message, render_to_string(MessageView, "message.html", message: message,
      user: user, previews: [], message_opts: message_opts)}
  end

  def push_private_message(socket, channel_id, body, client \\ Client) do
    channel_id
    |> create_private_message(body)
    |> render_message
    |> client.push_message(socket)
  end

  def create_and_push_new_message(socket, body, channel_id, user_id, opts, client \\ Client) do
    body
    |> create_message(user_id, channel_id, opts)
    |> render_message
    |> client.push_message(socket)
  end

  defp update_attachment_description(attachment, message, value, user) do
    Repo.transaction(fn ->
      message
      |> Message.update(%{edited_id: user.id})
      |> case do
        {:ok, message} ->
          attachment
          |> Attachment.update(%{description: value})
          |> case do
            {:ok, _attachment} ->
              {:ok, message}
            error ->
              Repo.rollback(:attachment_error)
              error
          end
        error -> error
      end
    end)
    |> case do
      {:ok, res} -> res
      {:error, _} -> {:error, nil}
    end
  end

  def message_action(socket, sender, client \\ Client)
  def message_action(socket, Utils.dataset("id", "delete-message") = sender, client) do
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    # Logger.info "delete-message: id: #{message_id}, #{inspect sender}"
    SweetAlert.swal_modal socket, ~g(Are you sure?),
      ~g(You will not be able to recover this message), "warning",
      [
        showCancelButton: true, closeOnConfirm: false, closeOnCancel: true,
        confirmButtonColor: "#DD6B55", confirmButtonText: ~g(Yes, delete it)
      ],
      confirm: fn _result ->
        close_cog socket, sender, client
        delete(socket, message_id, client)
        SweetAlert.swal socket, ~g"Deleted!", ~g"Your entry was been deleted", "success",
          timer: 2000, showConfirmButton: false
      end
  end
  def message_action(socket, Utils.dataset("id", "star-message") = sender, client) do
    assigns = socket.assigns
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    _star = StarredMessage.create! %{message_id: message_id,
      user_id: assigns.user_id, channel_id: assigns.channel_id}
    close_cog socket, sender, client
    client.broadcast! socket, "update:starred", %{}
  end

  def message_action(socket, Utils.dataset("id", "unstar-message") = sender, client) do
    assigns = socket.assigns
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    StarredMessage.delete! StarredMessage.get_by(user_id: assigns.user_id,
      message_id: message_id, channel_id: assigns.channel_id)
    close_cog socket, sender, client
    client.broadcast! socket, "update:starred", %{}
  end

  def message_action(socket, Utils.dataset("id", "pin-message") = sender, client) do
    assigns = socket.assigns
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    PinnedMessage.create!  %{message_id: message_id,
      user_id: assigns.user_id, channel_id: assigns.channel_id}
    close_cog socket, sender, client
    client.broadcast! socket, "update:pinned", %{}
  end

  def message_action(socket, Utils.dataset("id", "unpin-message") = sender, client) do
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    PinnedMessage.delete! PinnedMessage.get_by(message_id: message_id)
    close_cog socket, sender, client
    client.broadcast! socket, "update:pinned", %{}
  end

  def message_action(socket, Utils.dataset("id", "edit-message") = sender, client) do
    message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
    start_editing socket, message_id, client
    close_cog socket, sender, client
  end

  def message_action(socket, sender, client) do
    action = sender["dataset"]["id"]
    Logger.debug "message action: #{action}, sender: #{inspect sender}"
    close_cog socket, sender, client
  end

  def start_editing(socket, message_id, client \\ Client)
  def start_editing(socket, nil, client) do
    client.toastr socket, :warning, ~g(There are no messages to edit)
  end
  def start_editing(socket, message_id, client) do
    Rebel.put_assigns socket, :edit_message_id, message_id
    Logger.debug fn ->  "editing #{message_id}" end
    message = Message.get message_id, preload: [:attachments]
    body =
      case message.attachments do
        [] -> strip_mentions message.body
        [att | _] -> att.description
      end
      |> Poison.encode!
    client.async_js socket, set_editing_js(message_id, body)
  end

  def open_edit(socket, client \\ Client) do
    message_id = client.send_js! socket, "$('.messages-box li.message.own').last().attr('id')"
    start_editing socket, message_id, client
  end

  defp strip_mentions(body) do
    String.replace body, ~r/<a.+?mention-link[^@]+?(@[^<]+?)<\/a>/, "\\g{1}"
  end

  def delete(%{assigns: assigns} = socket, message_id, client \\ Client) do
    user = Accounts.get_user assigns.user_id, preload: [:account, :roles, user_roles: :role]
    message = Message.get message_id
    if UccSettings.allow_message_deleting && (user.id == message.user_id ||
      Permissions.has_permission?(user, "delete-message", assigns.channel_id)) do

      message = Message.get message_id, preload: [:attachments]

      case MessageService.delete_message message do
        {:ok, _} ->
          client.delete_message! message_id, socket
        _ ->
          client.toastr! socket, :error,
            ~g(There was an error deleting that message)
      end
    else
      client.toastr! socket, :error, ~g(You are not authorized to delete that message)
    end
    socket
  end

  # @doc """
  # Helper function
  # """
  # def new_or_edit_message(socket, _editing? = true, client \\ Client),
  #   do: edit_message(socket, client)

  # def new_or_edit_message(socket, _editing?, client \\ Client),
  #   do: new_message(socket, client)

  @doc """
  This is the entry point for a new message being posted.

  Fetches the message from the client textarea control, and calls the `create/5`
  API.
  """
  def new_message(socket, body, client \\ Client) do
    assigns = socket.assigns

    if body != "" do
      create(body, assigns.channel_id, assigns.user_id, socket)
    end

    client.clear_message_box(socket)
    socket
  end

  def edit_message(%{assigns: assigns} = socket, body, client \\ Client) do
    message_id = Rebel.get_assigns socket, :edit_message_id

    update(body, assigns.channel_id, assigns.user_id, message_id, socket, client)

    client.clear_message_box(socket)
    client.broadcast_js socket, clear_editing_js(message_id)
  end

  def cancel_edit(socket, client \\ Client) do
    message_id = Rebel.get_assigns socket, :edit_message_id
    client.clear_message_box(socket)
    client.broadcast_js socket, clear_editing_js(message_id)
  end

  defp close_cog(socket, sender, client) do
    MessageCog.close_cog socket, sender, client
    socket
  end

  defp set_editing_js(message_id, body) do
    """
    var input = $('.input-message');
    input.addClass('editing').val(#{body});
    input.closest('form').addClass('editing');
    input.autogrow();
    $('#' + '#{message_id}').addClass('editing');
    """
  end

  defp clear_editing_js(message_id) do
    """
    var input = $('.input-message');
    input.removeClass('editing').val('');
    input.closest('form').removeClass('editing');
    $('#' + '#{message_id}').removeClass('editing');
    """
  end

  @doc """
  Handle the request from the bot server to broadcast a response.

  """
  def broadcast_bot_message(channel, user_id, body)
  def broadcast_bot_message(%{} = channel, _user_id, body) do
    bot_id = Helpers.get_bot_id()
    message = create_message(String.replace(body, "\n", "<br>"), bot_id,
      channel.id,
      %{
        system: true,
        sequential: false,
      })

    UcxUccWeb.Endpoint.broadcast! CC.chan_room <> channel.name,
      "message:push", %{rendered: render_message(message)}
  end

  def broadcast_bot_message(channel_id, user_id, body) do
    channel_id
    |> Channel.get
    |> broadcast_bot_message(user_id, body)
  end

  def broadcast_system_message(%{} = channel, user_id, body) do
    message = create_system_message(channel.id, user_id, body)
    # {_, html} = render_message message
    resp = create_broadcast_message(message.id, channel.name, message)
    UcxUccWeb.Endpoint.broadcast! CC.chan_room <> channel.name,
      "message:new", resp
  end
  def broadcast_system_message(channel_id, user_id, body) do
    channel_id
    |> Channel.get
    |> broadcast_system_message(user_id, body)
  end

  def broadcast_private_message(%{} = channel, _user_id, body) do
    message = create_private_message(channel.id, body)
    html = render_message message
    resp = create_broadcast_message(message.id, channel.name, html)
    UcxUccWeb.Endpoint.broadcast! CC.chan_room <> channel.name,
      "message:new", resp
  end
  def broadcast_private_message(channel_id, user_id, body) do
    channel_id
    |> Channel.get
    |> broadcast_private_message(user_id, body)
  end

  def broadcast_message(id, room, user_id, html, opts \\ []) #event \\ "new")
  def broadcast_message(%{} = socket, id, user_id, html, opts) do
    event = opts[:event] || "new"
    Phoenix.Channel.broadcast! socket, "message:" <> event,
      create_broadcast_message(id, user_id, html, opts)
  end
  def broadcast_message(id, room, user_id, html, opts) do
    event = opts[:event] || "new"
    UcxUccWeb.Endpoint.broadcast! CC.chan_room <> room, "message:" <> event,
      create_broadcast_message(id, user_id, html, opts)
  end

  defp create_broadcast_message(id, user_id, message, opts \\ [])
  defp create_broadcast_message(id, user_id, %{body: body} = message, opts) do
    Enum.into opts, %{
      body: body,
      id: id,
      user_id: user_id,
      message: message
    }
  end
  defp create_broadcast_message(id, user_id, html, opts) do
    Enum.into opts,
      %{
        body: html,
        id: id,
        user_id: user_id
      }
  end

  def create_system_message(channel_id, user_id, body) do
    create_message(body, user_id, channel_id,
      %{
        system: true,
        sequential: false,
      })
  end

  # def create_private_message(channel_id, body) do
  #   bot_id = Helpers.get_bot_id()
  #   create_message(body, bot_id, channel_id,
  #     %{
  #       type: "p",
  #       system: true,
  #       sequential: false,
  #     })
  # end
end
