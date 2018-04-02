defmodule InfinityOnePages.Repo.Migrations.CreateAppVersions do
  use Ecto.Migration

  def change do
    create table(:app_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :assets_url, :string
      add :html_url, :string
      add :git_id, :integer
      add :tag_name, :string
      add :name, :string
      add :draft, :boolean, default: false, null: false
      add :prerelease, :boolean, default: false, null: false
      add :body, :text

      timestamps()
    end

    unique_index(:app_versions, [:name])
  end
end
