defmodule InfinityOnePages.Repo.Migrations.CreateAppAssets do
  use Ecto.Migration

  def change do
    create table(:app_assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :git_id, :integer
      add :name, :string
      add :content_type, :string
      add :state, :string
      add :download_count, :integer
      add :browser_download_url, :string
      add :version_id, references(:app_versions, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:app_assets, [:version_id])
  end
end
