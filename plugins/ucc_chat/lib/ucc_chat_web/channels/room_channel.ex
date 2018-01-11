defmodule UccChatWeb.RoomChannel do
  @moduledoc """
  Handle incoming and outgoing Subscription messages
  """
  use UccChatWeb, :channel
  use UccLogger

  use Rebel.Channel, name: "room", controllers: [
    UccChatWeb.ChannelController,
  ], intercepts: [
    "user:action",
    "room:state_change",
    "room:update:list",
    "room:delete",
    "update:topic",
    "update:description",
    "update:settings:name",
    "update:messages_header",
    "update:message_box",
    "update:name:change",
    "update:room-icon",
    "send:message",
    "js:execjs",
    "update:flex-button",
    # "update:mute_unmute",
    "update:remove_user",
    # "update:set_remove_owner",
    "broadcast:message",
    "broadcast:message:update",
    "message:new",
    "message:push",
    "message:new:attachment"
  ]

  alias UccChat.{
    Subscription, Channel, Message, ChatDat
  }
  alias UccChatWeb.RebelChannel.Client
  alias UccChatWeb.{MasterView, UserSocket}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUcc.{Permissions, Accounts}, warn: false
  alias UcxUccWeb.Endpoint
  alias UccChatWeb.RoomChannel.KeyStore
  alias UccChatWeb.RoomChannel.Message, as: WebMessage
  alias UccChatWeb.Client, as: WebClient

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false

  require UccChat.ChatConstants, as: CC

  onconnect :on_connect

  ############
  # API

  def on_connect(socket) do
    socket
  end

  def broadcast_room_field(room, field, value) do
    Endpoint.broadcast! CC.chan_room <> room, "update:#{field}", %{field: value}
  end

  def broadcast_name_change(room, new_room, user_id, channel_id) do
    Endpoint.broadcast! CC.chan_room <> room, "update:name:change",
      %{new_room: new_room, user_id: user_id, channel_id: channel_id}
  end

  def broadcast_room_settings_field(room, field, value) do
    Endpoint.broadcast! CC.chan_room <> room, "update:settings:#{field}", %{field: value}
  end

  def broadcast_messages_header(room, user_id, channel_id) do
    Endpoint.broadcast! CC.chan_room <> room, "update:messages_header",
      %{user_id: user_id, channel_id: channel_id}
  end

  def broadcast_message_box(room, channel_id, user_id) do
    Endpoint.broadcast! CC.chan_room <> room, "update:message_box",
      %{user_id: user_id, channel_id: channel_id, room: room}
  end

  def broadcast_message(message) do
    Logger.debug "message: #{inspect message}"
    channel = Channel.get message.channel_id
    Endpoint.broadcast! CC.chan_room <> channel.name, "broadcast:message",
      %{message: message}
  end

  def broadcast_bot_message(room, user_id, body) do
    WebMessage.broadcast_bot_message room, user_id, body
  end

  def broadcast_updated_message(message, _opts) do
    # IO.inspect message
    channel = Channel.get message.channel_id
    Endpoint.broadcast! CC.chan_room <> channel.name, "broadcast:message:update",
      %{message: message, channel: channel}
    # need to get channel_id from message
    # raise "TBD: Implement this"
  end

  def new_attachment(room, params) do
    Endpoint.broadcast! CC.chan_room <> room, "message:new:attachment", params
  end

  def user_join(nil), do: Logger.warn "join for nil username"
  def user_join(username, room) do
    # Logger.warn "user_join username: #{inspect username}, room: #{inspect room}"
    Endpoint.broadcast CC.chan_room <> room, "user:join", %{username: username}
  end

  def user_leave(nil), do: Logger.warn "leave for nil username"
  def user_leave(username, room) do
    Logger.debug "user_leave username: #{inspect username}, room: #{inspect room}"
    Endpoint.broadcast CC.chan_room <> room, "user:leave", %{username: username}
  end

  ############
  # Socket stuff

  def join(ev = CC.chan_room <> "lobby", msg, socket) do
    Logger.debug "user joined lobby msg: #{inspect msg}, socket: #{inspect socket}"
    super ev, msg, socket
  end

  def join(ev = CC.chan_room <> room, msg, socket) do
    trace ev, msg
    send self(), {:after_join, room, msg}
    super ev, msg, socket
  end

  def topic(_broadcasting, _controller, _request_path, conn_assigns) do
    # Logger.error "conn_assigns: #{inspect conn_assigns}"
    if conn_assigns.chatd.active_room == 0 do
      "lobby"
    else
      conn_assigns.chatd.active_room.name
    end
  end

  def handle_info({:after_join, room, msg}, socket) do
    :erlang.process_flag(:trap_exit, true)
    trace room, msg
    # Logger.warn "msg: " <> inspect(msg) <> ", user_id: " <> inspect(socket.assigns[:user_id])
    channel = Channel.get_by!(name: room)
    Process.send_after self(), :broadcast_user_join, 20

    push socket, "join", %{status: "connected"}

    socket =
      socket
      |> assign(:self, self())
      |> assign(:channel_id, channel.id)

    {:noreply, socket}
  end

  def handle_info(:broadcast_user_join, socket) do
    broadcast! socket, "user:entered", %{user_id: socket.assigns[:user_id],
      channel_id: socket.assigns[:channel_id]}
    {:noreply, socket}
  end

  def handle_info({:EXIT, _, :normal}, socket) do
    {:noreply, socket}
  end

  def handle_info(event, socket) do
    Logger.warn "unhandled event: #{inspect event}"
    {:noreply, socket}
  end

  ##########
  # Outgoing message handlers

  def handle_out("message:push", %{rendered: rendered}, socket) do
    WebClient.push_message(rendered, socket)
    {:noreply, socket}
  end

  def handle_out("message:new", %{message: %{system: true} = message}, socket) do
    message
    |> WebMessage.render_message
    |> WebClient.broadcast_message(socket)
    {:noreply, socket}
  end

  def handle_out("message:new", _payload, socket) do
    {:noreply, socket}
  end

  def handle_out("message:new:attachment", payload, socket) do
    if payload["user_id"] == socket.assigns.user_id do
      Logger.debug "matched user"
      WebMessage.create_attachment(payload, socket)
    end
    {:noreply, socket}
  end

  def handle_out("send:message" = ev, payload, socket) do
    trace ev, payload
    broadcast_js socket, payload[:js]
    {:noreply, socket}
  end

  def handle_out("js:execjs" = ev, payload, socket) do
    trace ev, payload

    case exec_js socket, payload[:js] do
      {:ok, result} ->
        send payload[:sender], {:response, result}
      {:error, error} ->
        send payload[:sender], {:error, error}
    end
    {:noreply, socket}
  end


  def handle_out("update:message_box", _payload, socket) do
    Client.broadcast_message_box socket, socket.assigns.channel_id,
      socket.assigns.user_id
    {:noreply, socket}
  end

  def handle_out("update:messages_header", payload, socket) do
    update_messages_header(socket, get_chatd(payload))
    {:noreply, socket}
  end

  def handle_out("update:name:change", payload, socket) do
    chatd = get_chatd(payload)
    ar = chatd.active_room

    socket
    |> update_messages_header(chatd)
    |> Client.replace_history(ar.name, ar.display_name)

    {:noreply, socket}
  end

  def handle_out(ev = "update:topic", %{field: field} = payload, socket) do
    debug ev, payload
    socket
    |> update!(:text, set: field, on: "header.fixed-title .room-topic")
    |> update!(:text, set: field, on: ~s(.current-setting[data-edit="topic"]))
    {:noreply, socket}
  end

  def handle_out(ev = "update:description", %{field: field} = payload, socket) do
    debug ev, payload
    update!(socket, :text, set: field,
      on: ~s(.current-setting[data-edit="description"]))
    {:noreply, socket}
  end

  def handle_out(ev = "update:room-icon", %{field: icon} = payload, socket) do
    debug ev, payload
    icon = String.replace(icon, ~r/^icon-/, "")
    Client.broadcast_room_icon(socket, socket.assigns.room, icon)
    {:noreply, socket}
  end

  def handle_out(ev = "update:settings:name", %{field: field} = payload, socket) do
    debug ev, payload
    socket
    |> update!(:text, set: field, on: ~s(.current-setting[data-edit="name"]))
    {:noreply, socket}
  end

  def handle_out(ev = "room:state_change", msg, %{assigns: assigns} = socket) do
    debug ev, msg, "assigns: #{inspect assigns}"
    channel_id = msg[:channel_id] || assigns[:channel_id] #  || msg[:channel_id]
    if channel_id do
      UserSocket.push_message_box(socket, channel_id, assigns.user_id)
    end

    {:noreply, socket}
  end

  def handle_out(ev = "user:action", msg, socket) do
    debug ev, msg
    {:noreply, socket}
  end

  def handle_out("room:update:list", _msg, socket) do
    {:noreply, socket}
  end

  def handle_out("room:delete", _msg, socket) do
    {:noreply, socket}
  end

  def handle_out(ev = "lobby:" <> event, msg, socket) do
    debug ev, msg
    user_id = socket.assigns[:user_id]
    channel_id = msg[:channel_id]

    if Subscription.get_by user_id: user_id, channel_id: channel_id do
      Endpoint.broadcast CC.chan_room <> "lobby", event, msg
    end

    # push socket, event, msg
    {:noreply, socket}
  end

  def handle_out("update:flex-button", %{username: username, html: html} = data, socket) do
    selector = ~s/.user-view[data-username="#{username}"] button.#{data.button}/
    socket
    |> execute(replaceWith: html, on: selector)
    |> set_event_handlers(selector)
    {:noreply, socket}
  end

  # def handle_out("update:mute_unmute", %{username: username, html: html}, socket) do
  #   selector = ~s/.user-view[data-username="#{username}"] button.mute-unmute/
  #   socket
  #   |> execute(replaceWith: html, on: selector)
  #   |> set_event_handlers(selector)
  #   {:noreply, socket}
  # end

  # def handle_out("update:set_remove_owner", %{username: username, html: html}, socket) do
  #   selector = ~s/.user-view[data-username="#{username}"] button.set-remove-owner/
  #   socket
  #   |> execute(replaceWith: html, on: selector)
  #   |> set_event_handlers(selector)
  #   {:noreply, socket}
  # end

  def handle_out("update:remove_user", %{username: username, js: js}, socket) do
    Logger.debug "username: #{username}"
    exec_js socket, js
    {:noreply, socket}
  end

  def handle_out("broadcast:message", %{message: message}, socket) do
    message = Message.preload_schema message, [:attachments, :user, :reactions]
    {_, html} = WebMessage.render_message message
    # Logger.warn "html: #{html}"
    WebMessage.broadcast_message(socket, message.id, message.user_id, html)
    {:noreply, socket}
  end

  def handle_out("broadcast:message:update", %{message: message}, socket) do
    WebMessage.update(message.body, message.channel_id, socket.assigns.user_id, message.id, socket)
    {:noreply, socket}
  end

# [[{{"bc47810a-29a3-4cd5-893b-13a5a2ebdd31", #PID<0.4000.0>}, %{keys: ""}}]]
  def terminate(_reason, %{assigns: assigns}) do
    Logger.debug "terminate: " <> inspect({assigns[:user_id], assigns[:self]})
    KeyStore.delete {assigns[:user_id], assigns[:self]}
    :ok
  end

  ##########
  # Incoming message handlers

  def handle_in(pattern, %{"params" => params, "ucxchat" =>  ucxchat} = msg,
    socket) do
    # debug pattern, msg
    trace pattern, msg

    user = Helpers.get_user! socket.assigns.user_id

    if authorized? socket, String.split(pattern, "/"), params, ucxchat, user do
      UccChatWeb.ChannelRouter.route(socket, pattern, params, ucxchat)
    else
      push socket, "toastr:error", %{message: ~g"You are not authorized!"}
      {:noreply, socket}
    end
  end

  def handle_in(ev = "messages:load", msg, socket) do
    debug ev, msg

    {:noreply, socket}
  end

  # def handle_in(ev = "message_popup:" <> cmd, msg, socket) do
  #   debug ev, msg
  #   resp = UccChat.MessagePopupService.handle_in(cmd, msg)
  #   {:reply, resp, socket}
  # end

  def handle_in(ev = "message_cog:" <> cmd, msg, socket) do
    debug ev, msg
    resp =
      case UccChat.MessageCogService.handle_in(cmd, msg, socket) do
        {:nil, msg} ->
          {:ok, msg}
        {event, msg} ->
          broadcast! socket, event, %{}
          {:ok, msg}
      end

    {:reply, resp, socket}
  end

  def handle_in(ev = "message:get-body:" <> id, msg, socket) do
    debug ev, msg

    message = Message.get id, preload: [:attachments]
    body =
      case message.attachments do
        [] -> message.body
        [att|_] -> att.description
      end
    {:reply, {:ok, %{body: body}}, socket}
  end
  # default case
  def handle_in(event, msg, socket) do
    Logger.warn "RoomChannel no handler for: event: #{event}, " <>
      "msg: #{inspect msg}"
    {:noreply, socket}
  end

  #########
  # Private

  @room_commands ~w(set-owner set-moderator mute-user remove-user)

  defp authorized?(_socket, ["room_settings" | _], _params, ucxchat, user) do
    Permissions.has_permission? user, "edit-room",
      ucxchat["assigns"]["channel_id"]
  end

  defp authorized?(_socket, _pattern = ["room", command, _username], _params,
    ucxchat, user) when command in @room_commands do

    Permissions.has_permission? user, command,
      ucxchat["assigns"]["channel_id"]
  end

  defp authorized?(_socket, _pattern, _params, _ucxchat, _), do: true

  defp update_messages_header(socket, %ChatDat{} = chatd) do
    html = Phoenix.View.render_to_string MasterView,
      "messages_header.html", chatd: chatd
    on = ".messages-container header>h2"
    update socket, :html, set: html, on: on
  end

  defp get_chatd(%{user_id: user_id, channel_id: channel_id}) do
    user = Helpers.get_user! user_id
    channel = Channel.get channel_id
    ChatDat.new user, channel
  end

  defdelegate message_keydown(socket, sender), to: UccChatWeb.RoomChannel.MessageInput
  defdelegate click_popup(socket, sender), to: UccChatWeb.RoomChannel.MessageInput
  defdelegate emoji_show(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate emoji_filter(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate emoji_select(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate emoji_tone_open(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate emoji_tone_select(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate emoji_search(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate reaction_open(socket, sender), to: UccChatWeb.RoomChannel.EmojiInput
  defdelegate message_cog_click(socket, sender), to: UccChatWeb.RoomChannel.MessageCog
  defdelegate jump_to_message(socket, sender), to: UccChatWeb.RoomChannel.MessageCog
  defdelegate flex_message_cog_click(socket, sender), to: UccChatWeb.RoomChannel.MessageCog
  defdelegate close_cog(socket, sender), to: UccChatWeb.RoomChannel.MessageCog
  defdelegate message_action(socket, sender), to: UccChatWeb.RoomChannel.Message
end
