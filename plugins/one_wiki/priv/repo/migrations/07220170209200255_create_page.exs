defmodule OneChat.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:wiki_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :body, :text
      add :type, :integer,  default: 0
      add :format, :string, default: "markdown"
      add :commit_message, :string
      add :commit, :string
      add :draft, :boolean, default: false
      add :parent_id, references(:wiki_pages, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
    create unique_index(:wiki_pages, [:title])
  end
end
