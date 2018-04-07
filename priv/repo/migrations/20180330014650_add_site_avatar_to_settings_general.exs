defmodule InfinityOnePages.Repo.Migrations.AddSiteAvatarToSettingsGeneral do
  use Ecto.Migration

  def change do
    alter table(:settings_general) do
      add :site_avatar, :string
      add :site_client_name, :string, default: "use-host-name"
    end
  end
end
