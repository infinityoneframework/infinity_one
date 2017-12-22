defmodule UcxUcc.Repo.Migrations.CreateUcxUcc.Accounts.Account do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
    create index(:accounts, [:user_id])
  end
end
