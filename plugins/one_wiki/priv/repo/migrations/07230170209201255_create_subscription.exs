defmodule OneWiki.Repo.Migrations.CreateSubscription do
  use Ecto.Migration

  def change do
    create table(:wiki_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :integer, default: 0
      add :alert, :boolean, default: false
      add :hidden, :boolean, default: false
      add :has_unread, :boolean, default: false
      add :ls, :utc_datetime                     # last seen
      add :f, :boolean, default: false          # favorite
      add :page_id, references(:wiki_pages, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
    create unique_index(:wiki_subscriptions, [:user_id, :page_id], name: :wiki_subscriptions_user_id_page_id_index)
  end
end
