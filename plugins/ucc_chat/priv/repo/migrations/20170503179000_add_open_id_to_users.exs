defmodule UccChat.Repo.Migrations.AddOpenIdToUsers do
  use Ecto.Migration

  def change do

    alter table(:accounts_users) do
      add :open_id, references(:channels, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:accounts_users, [:open_id])
  end
end
