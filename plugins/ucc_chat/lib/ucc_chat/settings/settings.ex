defmodule UccChat.Settings do
  use UccSettings

  alias UccChat.Notification

  def get_desktop_notification_duration(user, channel) do
    cond do
      not enable_desktop_notifications() ->
        nil
      not user.account.enable_desktop_notifications ->
        nil
      not is_nil(user.account.desktop_notification_duration) ->
        user.account.desktop_notification_duration
      true ->
        case Notification.get_notification(user.account_id, channel.id) do
          nil ->
            desktop_notification_duration()
          %{settings: %{duration: nil}} ->
            desktop_notification_duration()
          %{settings: %{duration: duration}} ->
            duration
        end
    end
  end

  def get_new_message_sound(user, channel_id) do
    default = get_system_new_message_sound()
    cond do
      user.account.new_message_notification == "none" ->
        nil
      user.account.new_message_notification != "system_default" ->
        user.account.new_message_notification
      true ->
        case Notification.get_notification(user.account_id, channel_id) do
          nil -> default
          %{settings: %{audio: "system_default"}} -> default
          %{settings: %{audio: "none"}} -> nil
          %{settings: %{audio: sound}} -> sound
        end
    end
  end

  def get_new_room_sound(user) do
    case user.account.new_room_notification do
      "none"           -> nil
      "system_default" -> get_system_new_room_sound()
      other            -> other
    end
  end

  def get_system_new_message_sound, do: "chime"

  def get_system_new_room_sound, do: "door"

  def get_system_message_sound, do: "none"

end
