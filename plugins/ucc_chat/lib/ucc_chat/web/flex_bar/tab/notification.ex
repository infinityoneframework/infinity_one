defmodule UccChat.Web.FlexBar.Tab.Notification do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.Notification
  alias UccChat.AccountService

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel group direct im],
      id: "notifications",
      title: ~g"Notifications",
      icon: "icon-bell-alt",
      view: View,
      template: "notifications.html",
      order: 40
    }
  end

  def args(user_id, channel_id, _, _) do
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

    [notification: notification, editing: nil]
  end
end

