defmodule UccChatWeb.FlexBar.Tab.Notification do
  use UccChatWeb.FlexBar.Helpers

  alias UccChat.Notification
  alias UccChat.AccountService
  alias UcxUcc.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group direct im],
      "notifications",
      ~g"Notifications",
      "icon-bell-alt",
      View,
      "notifications.html",
      50)
  end

  def args(socket, {user_id, channel_id, _, _}, params) do
    editing = params["editing"]
    current_user = Helpers.get_user! user_id
    notification =
      current_user.account
      |> Notification.get_notification(channel_id)
      |> case do
        nil ->
          AccountService.new_notification(current_user.account.id, channel_id)
        notification ->
          notification
      end

    assigns =
      socket
      |> Rebel.get_assigns()
      |> Map.put(:notification, notification)
      |> Map.put(:resource_key, :notification)

    Rebel.put_assigns(socket, assigns)

    {[notification: notification, editing: editing], socket}
  end

  def play(socket, _sender) do
    play_sound socket, socket.assigns.notification.settings.audio
  end

  def change_audio(socket, sender) do
    play_sound socket, sender["value"]
  end

  def play_sound(socket, sound) do
    exec_js socket, "document.getElementById('#{sound}').play()"
    socket
  end
end
