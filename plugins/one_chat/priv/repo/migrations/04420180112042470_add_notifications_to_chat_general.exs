defmodule InfinityOne.Repo.Migrations.AddNotificationsToChatGeneral do
  use Ecto.Migration

  def change do
    alter table(:settings_chat_general) do
      add :unread_count, :string, default: "user_and_group"
      add :unread_count_dm, :string, default: "all"
      add :default_message_notification_audio, :string, default: "chime"
      add :audio_notifications_default_alert, :string, default: "mentions"
      add :desktop_notifications_default_alert, :string, default: "mentions"
      add :mobile_notifications_default_alert, :string, default: "mentions"
      add :max_members_disable_notifications, :integer, default: 100
      add :first_channel_after_login, :string, default: ""
    end
  end
end
