defmodule UccChat.Repo.Migrations.AddChatFieldsToUsers do
  use Ecto.Migration

  def change do

    alter table(:accounts_users) do
      add :open_id, references(:channels, on_delete: :nilify_all, type: :binary_id)
      add :chat_status, :string
    end

    create index(:accounts_users, [:open_id])
  end
end
