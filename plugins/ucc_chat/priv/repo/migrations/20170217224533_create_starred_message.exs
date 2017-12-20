defmodule UccChat.Repo.Migrations.CreateStarredMessage do
  use Ecto.Migration

  def change do
    create table(:starred_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)
      add :message_id, references(:messages, on_delete: :delete_all, type: :binary_id)
      add :channel_id, references(:channels, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
      # timestamps()
    end
    create index(:starred_messages, [:user_id])
    create index(:starred_messages, [:message_id])
    create index(:starred_messages, [:channel_id])

  end
end
