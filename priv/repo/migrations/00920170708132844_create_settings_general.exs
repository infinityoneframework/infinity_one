defmodule UcxUcc.Repo.Migrations.CreateSettingsGeneral do
  use Ecto.Migration

  def change do
    create table(:settings_general, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :site_url, :string, default: "change-this"
      add :site_name, :string, default: "UccChat"
      add :enable_desktop_notifications, :boolean, default: true
      add :desktop_notification_duration, :integer, default: 8
    end
  end
end
