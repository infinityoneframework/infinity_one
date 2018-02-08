defmodule UccChatWeb.UserChannel.Notifier do
  @moduledoc """
  Handle notifications for the UserChannel.
  """

  alias UccChat.{Subscription, Settings}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUcc.Accounts

  require Logger

  def new_message(payload, socket, client \\ UccChatWeb.Client)

  def new_message(%{message: %{user_id: user_id}}, %{assigns: %{user_id: user_id}} = socket, _client) do
    # Ignore for your own message

    # user = Accounts.get_user(user_id, preload: [:account])
    # IO.inspect user.username, label: "new_message ignore"
    socket
  end

  def new_message(payload, socket, client) do
    user_id = payload.user_id
    channel = payload.channel
    # room = channel.name

    UccChatWeb.UserChannel.audit_open_rooms(socket)

    subscription = Subscription.get_by(channel_id: channel.id, user_id: user_id, preload: [:channel])
    open = Map.get(subscription, :open)
    active_open = payload.user_state == "active" and open
    user = Accounts.get_user(user_id, preload: [:account])

    # IO.inspect {user.username, user.id, payload.message.user_id}, label: "new_message"
    cond do
      not active_open ->
        socket
        |> broadcast_unread_alert(channel.name, client)
        |> handle_notifications(user, channel, payload, client)
      true ->
        socket
    end
  end

  def broadcast_unread_alert(socket, channel_name, client) do
    client.broadcast_js socket, """
      $('.link-room-#{channel_name}')
        .addClass('has-unread')
        .addClass('has-alert')
      """
    socket
  end

  def broadcast_unread_count(socket, channel_name, count, client) do
    client.broadcast_js socket, """
      $('.link-room-#{channel_name}') .find('.unread').remove();
      $('.link-room-#{channel_name} a.open-room')
        .prepend('<span class="unread">#{count}</span>');
      """
    socket
  end

  defp handle_notifications(socket, user, channel, payload, client) do
    message = payload.message

    mention = !!Enum.find(message.mentions, & &1.user_id == user.id)
    mention_or_direct = mention or channel.type == 2

    if sound = Settings.get_new_message_sound(user, channel.id, mention_or_direct) do
      client.notify_audio(socket, sound)
    end

    if mention_or_direct do
      count = Subscription.get_unread(channel.id, user.id) + 1
      Subscription.set_unread(channel.id, user.id, count)
      broadcast_unread_count(socket, channel.name, count, client)

      if UccSettings.enable_desktop_notifications() do
        client.desktop_notify(socket,
          message.user.username,
          Helpers.strip_tags(message.body),
          message,
          Settings.get_desktop_notification_duration(user, channel))
      else
        broadcast_client_notification socket, [badges_only: true], client
      end

    end
  end

  def broadcast_client_notification(socket, opts \\ %{}, client \\ UccChatWeb.Client) do
    payload = opts |> Enum.into(%{}) |> Poison.encode!()

    client.broadcast_js socket, "UccChat.roomManger.notification(#{payload});"
  end
  # def handle_info({:update_mention, payload, user_id} = ev, socket) do
  #   trace "upate_mention", ev

  #   if UserService.open_channel_count(socket.assigns.user_id) > 1 do
  #     opens = UserService.open_channels(socket.assigns.user_id)
  #     Logger.error "found more than one open, room: " <>
  #       "#{inspect socket.assigns.room}, opens: #{inspect opens}"
  #   end

  #   %{channel_id: channel_id, body: body} = payload
  #   channel = Channel.get!(channel_id)

  #   with sub <- Subscription.get_by(channel_id: channel_id,
  #                   user_id: user_id),
  #        open  <- Map.get(sub, :open),
  #        false <- socket.assigns.user_state == "active" and open,
  #        count <- ChannelService.get_unread(channel_id, user_id) do
  #     push(socket, "room:mention", %{room: channel.name, unread: count})

  #     if body do
  #       body = Helpers.strip_tags body
  #       user = Helpers.get_user user_id
  #       lhandle_notifications socket, user, channel, %{body: body,
  #         username: socket.assigns.username, mention: payload[:mention]}
  #     end
  #   end
  #   {:noreply, socket}
  # end

  # def handle_info({:update_direct_message, payload, user_id} = ev, socket) do
  #   trace "upate_direct_message", ev, socket.assigns.user_state

  #   %{channel_id: channel_id, msg: msg} = payload
  #   channel = Channel.get!(channel_id)

  #   with [sub] <- Repo.all(Subscription.get(channel_id, user_id)),
  #        # _ <- Logger.warn("update_direct_message unread: #{sub.unread}"),
  #        open  <- Map.get(sub, :open),
  #        # _ <- Logger.warn("open: #{inspect open}"),
  #        false <- socket.assigns.user_state == "active" and open,
  #        count <- ChannelService.get_unread(channel_id, user_id) do
  #     push(socket, "room:mention", %{room: channel.name, unread: count})

  #     # Logger.warn "msg: " <> inspect(msg)
  #     if msg do
  #       user = Helpers.get_user(user_id)
  #       handle_notifications socket, user, channel,
  #         update_in(msg, [:body], &Helpers.strip_tags/1)
  #     end
  #   end
  #   {:noreply, socket}
  # end

end
