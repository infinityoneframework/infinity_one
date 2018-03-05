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

    UccChatWeb.UserChannel.audit_open_rooms(socket)

    active_open = payload.user_state == "active" and payload.open
    user = Accounts.get_user(user_id, preload: [:account])

    all! = Enum.find(payload.message.mentions, & &1.user_id == user.id && &1.name == "all!")

    unless is_nil all! do
      UccChatWeb.RebelChannel.Client.add_caution_announcement(socket, payload.message.body)
    end

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
    mention_or_direct = mention or channel.type == 2 or channel.nway

    if sound = Settings.get_new_message_sound(user, channel.id, mention_or_direct) do
      client.notify_audio(socket, sound)
    end

    if mention_or_direct do
      if payload.open do
        Subscription.inc_unread(channel.id, user.id)
      end
      count = Subscription.get_unread(channel.id, user.id)
      broadcast_unread_count(socket, channel.name, count, client)
    end

    if UccChat.Settings.desktop_notification?(user, channel.id, mention_or_direct) do
      client.desktop_notify(socket,
        message.user.username,
        Helpers.strip_tags(message.body),
        message,
        Settings.get_desktop_notification_duration(user, channel))
    else
      if mention_or_direct do
        broadcast_client_notification socket, [badges_only: true], client
      end
    end
    socket
  end

  def broadcast_client_notification(socket, opts \\ %{}, client \\ UccChatWeb.Client) do
    payload = opts |> Enum.into(%{}) |> Poison.encode!()

    client.broadcast_js socket, "UccChat.roomManger.notification(#{payload});"
  end
end
