defmodule OneWiki.Repo.Migrations.CreateSettingsWiki do
  use Ecto.Migration
  use InfinityOneWeb.Gettext

  def change do
    create table(:settings_wiki, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :wiki_enabled, :boolean, default: false
      add :wiki_side_nav_title, :string, default: gettext("Pages")
      add :wiki_history_enabled, :boolean, default: false
      add :wiki_languages, :string, default: "markdown"
      add :wiki_storage_path, :string, default: "priv/static/uploads/pages"
      add :wiki_default_language, :string, default: "markdown"
    end
  end
end
