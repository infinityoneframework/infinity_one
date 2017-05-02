defmodule UcxUcc.Repo.Migrations.CreateUcxUcc.Permissions.PermissionRole do
  use Ecto.Migration

  def change do
    create table(:permissions_permissions_roles) do
      add :permission_id, references(:permissions_permissions, on_delete: :delete_all)
      add :role_id, references(:accounts_roles, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:permissions_permissions_roles, [:permission_id])
    create index(:permissions_permissions_roles, [:role_id])
  end
end
