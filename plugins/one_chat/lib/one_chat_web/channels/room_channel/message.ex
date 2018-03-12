defmodule OneChatWeb.RoomChannel.Message do
  @moduledoc """
  Handle message related functionality for Web access.

  """
  use OneLogger
  use OneChatWeb.Channel.Utils

  import InfinityOneWeb.Gettext
  import InfinityOneWeb.Utils
  import InfinityOne.Permissions, only: [has_permission?: 3]

  alias InfinityOne.{Accounts, Repo}
  alias OneChat.{Channel, Message, StarredMessage, PinnedMessage, Subscription}
  alias OneChat.ServiceHelpers, as: Helpers
  alias Rebel.SweetAlert
  alias OneChatWeb.RoomChannel.MessageCog
  alias OneChatWeb.{MessageView, Client}
  alias OneChat.{MessageAgent}
  alias OneChat.{ChatDat}

  require OneChat.ChatConstants, as: CC

  @doc """
  Update and edited message.
  """
  def update_message(socket, value, client) do
    message_id = Rebel.get_assigns(socket, :edit_message_id)

    message = OneChat.Message.get(message_id, preload: [:attachments])

    attrs =
      message.attachments
      |> case do
        [] ->
          %{body: value}
        attachments ->
          [first | rest] = Enum.map(attachments, & %{id: &1.id})
          %{attachments: [Map.put(first, :description, value) | rest]}
      end
      |> Map.put(:edited_id, socket.assigns.user_id)

    OneChat.Message.update(message, attrs)

    client.async_js socket, clear_editing_js(message_id)
  end

  @doc """
  Create a new message.
  """
  def new_message(socket, value, _client) do
    if value != "" do

      assigns = socket.assigns
      OneChat.Message.create(%{
        body: value,
        channel_id: assigns.channel_id,
        user_id: assigns.user_id
      })
    end
  end

  def create_private_message(channel_id, body) do
    Logger.warn "deprecated"
    bot_id = Helpers.get_bot_id()
    create_message(body, bot_id, channel_id,
      %{
        system: true,
        sequential: false,
      })
  end

  def create_message(body, user_id, channel_id, params \\ %{}) do
    Logger.warn "deprecated"
    Logger.warn "params: " <> inspect(params)

    Map.merge(
      %{
        channel_id: channel_id,
        user_id: user_id,
        body: body
      }, params)
    |> OneChat.Message.create
    |> Repo.preload(OneChat.Message.preloads())
    |> case do
      {:ok, message} ->
        if params[:type] == "p" do
          Repo.delete(message)
        else
          embed_link_previews(body, channel_id, message.id)
        end
        message
      error ->
        error
    end
  end

  def render_message(message, user_id) do
    Logger.debug fn -> inspect(message.body) end
    user = Accounts.get_user user_id
    message_opts = OneChatWeb.MessageView.message_opts()
    message = Message.preload_schema(message, OneChat.Message.preloads())

    {message, render_to_string(MessageView, "message.html", message: message,
      user: user, previews: [], message_opts: message_opts)}
  end

  def render_reactions(message, user_id) do
    user = Accounts.get_user user_id
    message_opts = OneChatWeb.MessageView.message_opts()
    message = Message.preload_schema(message, OneChat.Message.preloads())

    {message, render_to_string(MessageView, "reactions.html", message: message,
      user: user, message_opts: message_opts)}
  end

  def push_private_message(socket, channel_id, body, client \\ Client) do
    Logger.warn "deprecated"
    channel_id
    |> create_private_message(body)
    |> render_message(socket.assigns.user_id)
    |> client.push_message(socket)
  end

  def create_and_push_new_message(socket, body, channel_id, user_id, opts, client \\ Client) do
    Logger.warn "deprecated"
    body
    |> create_message(user_id, channel_id, opts)
    |> render_message(socket.assigns.user_id)
    |> client.push_message(socket)
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

        message = Message.get(message_id, preload: [:attachments])
        case Message.delete(message, socket.assigns.user_id) do
          {:ok, _} ->
            SweetAlert.swal socket, ~g"Deleted!",
              ~g"Your entry was been deleted", "success", timer: 2000,
              showConfirmButton: false
          {:error, %{errors: errors} = changeset} ->
            error =
              if Enum.any? errors, fn {_, {_, item}} -> item == [validation: :unauthorized] end do
                ~g(You are not authorized for that action)
              else
                OneChatWeb.SharedView.format_errors(changeset)
              end
            SweetAlert.swal socket, ~g"Sorry!",
              error, "error", timer: 3000, showConfirmButton: false
        end
      end
    socket
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
    user = Accounts.get_user assigns.user_id, default_preload: true
    if has_permission? user, "pin-message", assigns.channel_id do
      message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
      PinnedMessage.create!  %{message_id: message_id,
        user_id: assigns.user_id, channel_id: assigns.channel_id}
      close_cog socket, sender, client
      client.broadcast! socket, "update:pinned", %{}
    else
      client.toastr socket, :error, ~g(Unauthorized)
    end
  end

  def message_action(socket, Utils.dataset("id", "unpin-message") = sender, client) do
    assigns = socket.assigns
    user = Accounts.get_user assigns.user_id, default_preload: true
    if has_permission? user, "pin-message", assigns.channel_id do
      message_id = client.closest(socket, Rebel.Core.this(sender), "li.message", "id")
      PinnedMessage.delete! PinnedMessage.get_by(message_id: message_id)
      close_cog socket, sender, client
      client.broadcast! socket, "update:pinned", %{}
    else
      client.toastr socket, :error, ~g(Unauthorized)
    end
  end

  def message_action(socket, Utils.dataset("id", "edit-message") = sender, client) do
    user = Accounts.get_user socket.assigns.user_id, default_preload: true
    with message_id <- client.closest(socket, Rebel.Core.this(sender), "li.message", "id"),
         false <- is_nil(message_id),
         message <- Message.get(message_id, preload: [:attachments]),
         false <- is_nil(message),
         true <- message.user_id == user.id or has_permission?(user, "edit-message",
          socket.assigns.channel_id) do
      start_editing socket, message, client
    else
      true ->
        client.toastr socket, :warning, ~g(There are no message to edit)
      false ->
        client.toastr(socket, :error, ~g(Unauthorized))
    end
    close_cog socket, sender, client
  end

  def message_action(socket, sender, client) do
    action = sender["dataset"]["id"]
    Logger.debug "message action: #{action}, sender: #{inspect sender}"
    close_cog socket, sender, client
  end

  def start_editing(socket, message, client) do
    Rebel.put_assigns socket, :edit_message_id, message.id
    Logger.debug fn ->  "editing #{message.id}" end
    body =
      case message.attachments do
        [] -> strip_mentions message.body
        [att | _] -> att.description
      end
      |> Poison.encode!
    client.async_js socket, set_editing_js(message.id, body)
  end

  def open_edit(socket, client \\ Client) do
    message_id = client.send_js! socket, "$('.messages-box li.message.own').last().attr('id')"
    start_editing socket, message_id, client
  end

  defp strip_mentions(body) do
    String.replace body, ~r/<a.+?mention-link[^@]+?(@[^<]+?)<\/a>/, "\\g{1}"
  end

  def delete(%{assigns: assigns} = socket, message_id, _client \\ Client) do
    Logger.warn "deprecated"
    user = Accounts.get_user assigns.user_id, preload: [:account, :roles, user_roles: :role]
    message = Message.get message_id
    Message.delete message, user
    socket
  end

  def rebuild_sequentials(message) do
    Logger.warn "deprecated"
    spawn fn ->
      message.inserted_at
      |> Message.get_by_later(message.channel_id)
      |> Enum.reduce({nil, nil}, fn message, acc ->
        case {acc, message} do
          {_, %{system: true}} ->
            {nil, nil}
          {{last_message, user_id}, %{user_id: user_id, sequential: false, inserted_at: inserted_at}} ->
            if Message.sequential_message?(last_message, user_id, inserted_at) do
              Message.update message, %{sequential: true}
              Process.sleep(10)
            end
            {message, user_id}
          {{_, uid1}, %{user_id: user_id, sequential: true}} when uid1 != user_id ->
            Message.update message, %{sequential: false}
            Process.sleep(10)
            {message, user_id}
          {_, %{user_id: user_id}} ->
            {message, user_id}
        end
      end)
    end
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

  def clear_editing_js(message_id) do
    """
    var input = $('.input-message');
    input.removeClass('editing').val('');
    input.closest('form').removeClass('editing');
    $('#' + '#{message_id}').removeClass('editing');
    """
  end

  def bot_response_message(channel, _user_id, body) do
    Message.create(%{
      user_id: Helpers.get_bot_id(),
      channel_id: channel.id,
      body: String.replace(body, "\n", "<br>"),
      sequential: false,
      system: true
    })
  end

  def broadcast_system_message(%{} = channel, user_id, body) do
    Logger.warn "deprecated"
    # message = create_system_message(channel.id, user_id, body)
    Message.create_system_message(channel.id, user_id, body)
        # resp = create_broadcast_message(message.id, channel.name, message)
    # InfinityOneWeb.Endpoint.broadcast! CC.chan_room <> channel.name,
    #   "message:new", resp
  end

  def broadcast_system_message(channel_id, user_id, body) do
    Logger.warn "deprecated"
    channel_id
    |> Channel.get
    |> broadcast_system_message(user_id, body)
  end

  def broadcast_private_message(%{} = channel, user_id, body) do
    raise "deprecated"
    message = create_private_message(channel.id, body)
    html = render_message message, user_id
    resp = create_broadcast_message(message.id, channel.name, html)
    InfinityOneWeb.Endpoint.broadcast! CC.chan_room <> channel.name,
      "message:new", resp
  end

  def broadcast_private_message(channel_id, user_id, body) do
    Logger.warn "deprecated"
    channel_id
    |> Channel.get
    |> broadcast_private_message(user_id, body)
  end

  def broadcast_message(id, room, user_id, html, opts \\ []) #event \\ "new")
  def broadcast_message(%{} = socket, id, user_id, html, opts) do
    Logger.warn "deprecated"
    event = opts[:event] || "new"
    if event == "new" do
      raise "deprecated"
    end
    Phoenix.Channel.broadcast! socket, "message:" <> event,
      create_broadcast_message(id, user_id, html, opts)
  end

  def broadcast_message(id, room, user_id, html, opts) do
    Logger.warn "deprecated"
    event = opts[:event] || "new"
    InfinityOneWeb.Endpoint.broadcast! CC.chan_room <> room, "message:" <> event,
      create_broadcast_message(id, user_id, html, opts)
  end

  defp create_broadcast_message(id, user_id, message, opts \\ [])
  defp create_broadcast_message(id, user_id, %{body: body} = message, opts) do
    Logger.warn "deprecated"
    Enum.into opts, %{
      body: body,
      id: id,
      user_id: user_id,
      message: message
    }
  end
  defp create_broadcast_message(id, user_id, html, opts) do
    Logger.warn "deprecated"
    Enum.into opts,
      %{
        body: html,
        id: id,
        user_id: user_id
      }
  end

  def create_system_message(channel_id, user_id, body) do
    Logger.warn "deprecated"
    create_message(body, user_id, channel_id,
      %{
        system: true,
        sequential: false,
      })
  end

  def get_messages_info(%{} = page, channel_id, user) do
    subscription = Subscription.get(channel_id, user.id)
    last_read = Map.get(subscription || %{}, :last_read, "")

    %{}
    |> Map.put(:page, %{
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages
    })
    |> Map.put(:can_preview, true)
    |> Map.put(:last_read, last_read)
  end

  def get_messages_info(messages, channel_id, user) do
    subscription = Subscription.get(channel_id, user.id)
    has_more =
      with [first|_] <- messages,
           _ <- Logger.debug("get_messages_info 2"),
           first_msg when not is_nil(first_msg) <-
            Message.first_message(channel_id) do
        first.id != first_msg.id
      else
        _res -> false
      end
    has_more_next =
      with last when not is_nil(last) <- List.last(messages),
           last_msg when not is_nil(last_msg) <-
              Message.last_message(channel_id) do
        last.id != last_msg.id
      else
        _res -> false
      end

   %{
      has_more: has_more,
      has_more_next: has_more_next,
      can_preview: true,
      last_read: Map.get(subscription || %{}, :last_read, ""),
    }
  end

  # TODO: This should be called merge, not into
  def messages_info_into(messages, channel_id, user, params) do
    messages |> get_messages_info(channel_id, user) |> Map.merge(params)
  end

  def last_user_id(channel_id) do
    Logger.warn "deprecated. Please use Message.last_user_id/1 instead."
    case Message.last_message channel_id do
      nil     -> nil
      message -> Map.get(message, :user_id)
    end
  end

  def embed_link_previews(body, channel_id, message_id) do
    if OneSettings.embed_link_previews() do
      case get_preview_links body do
        [] ->
          :ok
        list ->
          do_embed_link_previews(list, channel_id, message_id)
      end
    end
  end

  def get_preview_links(nil), do: []
  def get_preview_links(body) do
    ~r/https?:\/\/[^\s]+/
    |> Regex.scan(body)
    |> List.flatten
  end

  def do_embed_link_previews(list, channel_id, message_id) do
    room = (Channel.get(channel_id) || %{}) |> Map.get(:name)

    Enum.each(list, fn url ->
      spawn fn ->
        case MessageAgent.get_preview url do
          nil ->

            html =
              MessageAgent.put_preview url, create_link_preview(url, message_id)

            broadcast_link_preview(html, room, message_id)
          html ->
            spawn fn ->
              :timer.sleep(100)
              broadcast_link_preview(html, room, message_id)
            end
        end
      end
    end)
  end

  defp create_link_preview(url, _message_id) do
    case LinkPreview.create url do
      {:ok, page} ->
        img =
          case Enum.find(page.images, &String.match?(&1[:url], ~r/https?:\/\//)) do
            %{url: url} -> url
            _ -> nil
          end

        "link_preview.html"
        |> MessageView.render(page: struct(page, images: img))
        |> Helpers.safe_to_string

      _ -> ""
    end
  end

  defp broadcast_link_preview(nil, _room, _message_id) do
    nil
  end

  defp broadcast_link_preview(html, room, message_id) do
    InfinityOneWeb.Endpoint.broadcast! CC.chan_room <> room, "message:preview",
      %{html: html, message_id: message_id}
  end

  def message_previews(user_id, %{entries: entries}) do
    message_previews(user_id, entries)
  end

  def message_previews(user_id, messages) when is_list(messages) do
    Enum.reduce messages, [], fn message, acc ->
      case get_preview_links(message.body) do
        [] -> acc
        list ->
          html_list = get_preview_html(list)
          for {url, html} <- html_list, is_nil(html) do
            spawn fn ->
              html = MessageAgent.put_preview url, create_link_preview(url, message.id)
              InfinityOneWeb.Endpoint.broadcast!(CC.chan_user <> user_id, "message:preview",
                %{html: html, message_id: message.id})
            end
          end
          [{message.id, html_list} | acc]
      end
    end
  end

  defp get_preview_html(list) do
    Enum.map list, &({&1, MessageAgent.get_preview(&1)})
  end

  def encode_mentions(body, channel_id) do
    body
    |> encode_user_mentions(channel_id)
    |> encode_channel_mentions
  end

  def encode_channel_mentions({body, acc}) do
    re = ~r/(^|\s|\!|:|,|\?)#([\.a-zA-Z0-9_-]*)/
    body =
      if (list = Regex.scan(re, body)) != [] do
        Enum.reduce(list, body, fn [_, _, name], body ->
          encode_channel_mention(name, body)
        end)
      else
        body
      end
    {body, acc}
  end

  def encode_channel_mention(name, body) do
    Channel.get_by(name: name)
    |> do_encode_channel_mention(name, body)
  end

  def do_encode_channel_mention(nil, _, body) do
    body
  end
  def do_encode_channel_mention(_channel, name, body) do
    name_link = " <a class='mention-link' data-channel='#{name}'>##{name}</a> "
    String.replace body, ~r/(^|\s|\.|\!|:|,|\?)##{name}[\.\!\?\,\:\s]*/, name_link
  end

  def encode_user_mentions(body, channel_id) do
    re = ~r/(^|\s|\!|:|,|\?)@([\.a-zA-Z0-9_-]*)/
    if (list = Regex.scan(re, body)) != [] do
      Enum.reduce(list, {body, []}, fn [_, _, name], {body, acc} ->
        encode_user_mention(name, body, channel_id, acc)
      end)
    else
      {body, []}
    end
  end

  def encode_user_mention(name, body, channel_id, acc) do
    name
    |> Accounts.get_by_username()
    |> do_encode_user_mention(name, body, channel_id, acc)
  end

  def do_encode_user_mention(nil, name, body, _, acc) when name in ~w(all here) do
    name_link = " <a class='mention-link mention-link-me mention-link-" <>
      "#{name} background-attention-color' >@#{name}</a> "
    body = String.replace body,
      ~r/(^|\s|\.|\!|:|,|\?)@#{name}[\.\!\?\,\:\s]*/, name_link
    {body, [{nil, name}|acc]}
  end

  def do_encode_user_mention(nil, _, body, _, acc) do
    {body, acc}
  end

  def do_encode_user_mention(user, name, body, _channel_id, acc) do
    name_link =
      " <a class='mention-link' data-username='#{user.username}'>@#{name}</a> "
    body =
      String.replace body, ~r/(^|\s|\.|\!|:|,|\?)@#{name}[\.\!\?\,\:\s]*/,
        name_link
    {body, [{user.id, name}|acc]}
  end

  def update_direct_notices(%{type: 2, id: id}, %{user_id: user_id}) do
    id
    |> Subscription.get_by_channel_id_and_not_user_id(user_id)
    |> Enum.each(fn %{unread: unread} = sub ->
      Subscription.update(sub, %{unread: unread + 1})
    end)
  end

  def update_direct_notices(_channel, _message) do
    nil
  end

  # TODO: I believe this should be moved to a room related module
  def render_message_box(channel_id, user_id) do
    user = Helpers.get_user! user_id
    channel =
      case Channel.get(channel_id) do
        nil ->
          Channel.first
        channel ->
          channel
      end

    chatd = ChatDat.new(user, channel)

    "message_box.html"
    |> MessageView.render(chatd: chatd, mb: MessageView.get_mb(chatd))
    |> Helpers.safe_to_string
  end
end
