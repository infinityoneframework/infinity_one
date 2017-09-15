defmodule UccChatWeb.RoomChannel.Message do
  use UccLogger

  import UcxUccWeb.Gettext
  import UcxUccWeb.Utils

  alias UcxUcc.{Accounts, Repo, Permissions}
  alias UccChat.{ChannelService, RobotService}
  alias UccChat.{Channel, Message}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.MessageService, as: Service
  alias __MODULE__.Client

  alias UccChatWeb.MessageView

  @preloads [:user, :edited_by, :attachments, :reactions]

  def create(body, channel_id, user_id, socket, client \\ Client) do
    user = Accounts.get_user user_id
    channel = Channel.get!(channel_id)
    msg_params = if Channel.direct?(channel), do: %{type: "d"}, else: %{}

    cond do
      ChannelService.user_muted? user_id, channel_id ->
        push_system_message socket, channel_id,
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
        handle_new_message socket, body,
          [channel: channel,
          user: user,
          msg_params: msg_params], client

        # {body, mentions} = encode_mentions(message, channel_id)
        # UccChat.RobotService.new_message body, channel, user

        # message = create_message(body, user_id, channel_id, msg_params)
        # create_mentions(mentions, message.id, message.channel_id, body)
        # update_direct_notices(channel, message)
        # message_html = render_message(message)
        # broadcast_message(socket, message.id, message.user.id,
        #   message_html, body: body)
    end
    Service.stop_typing(socket, user_id, channel_id)
    socket
  end

  defp handle_new_message(socket, message_body, opts, client \\ Client) do
    Logger.debug "handle_new_message #{inspect message_body}"
    user = opts[:user]
    channel = opts[:channel]
    channel_id = channel.id

    {body, mentions} = Service.encode_mentions(message_body, channel_id)

    RobotService.new_message body, channel, user

    message = create_message(body, user.id, channel_id, opts[:msg_params])

    Service.create_mentions(mentions, message.id, message.channel_id, body)

    Service.update_direct_notices(channel, message)

    message
    |> render_message
    |> client.broadcast_message(socket)
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

    {message, render_to_string(MessageView, "message.html", message: message,
      user: user, previews: [])}
  end

  def push_system_message(socket, channel_id, body, client \\ Client) do
    channel_id
    |> create_system_message(body)
    |> render_message
    |> client.push_message(socket)
  end

  def create_and_push_new_message(socket, body, channel_id, user_id, opts, client \\ Client) do
    body
    |> create_message(user_id, channel_id, opts)
    |> render_message
    |> client.push_message(socket)
  end
end
