defmodule InfinityOne.Repo.Migrations.AddDiskQuotaToFileupload do
  use Ecto.Migration

  def change do
    alter table(:settings_file_upload) do
      add :disk_quota_remaining_enabled, :boolean, default: true
      add :disk_quota_remaining_mb, :integer, default: 1_500
      add :disk_quota_size_enabled, :boolean, default: false
      add :disk_quota_size_mb, :integer, default: 5_000
      add :disk_quota_percent_enabled, :boolean, default: false
      add :disk_quota_percent, :integer, default: 50
    end
  end
end
