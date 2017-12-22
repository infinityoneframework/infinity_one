defmodule UcxUcc.Repo.Migrations.CreateUsersRoles do
  use Ecto.Migration

  def change do
    # create table(:accounts_users_roles, primary_key: false) do
    #   add :id, :binary_id, primary_key: true
    create table(:users_roles) do
      # add :role, :string, null: false
      add :scope, :binary_id, default: nil
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :role_id, references(:roles, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
    create index(:users_roles, [:user_id])
    create index(:users_roles, [:role_id])
    create index(:users_roles, [:scope])
    create unique_index(:users_roles, [:user_id, :role_id, :scope])

  end
end
