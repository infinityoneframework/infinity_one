defmodule InfinityOne.Repo.Migrations.CreateInfinityOne.Permissions.PermissionRole do
  use Ecto.Migration

  def change do
    create table(:permissions_roles) do
      add :permission_id, references(:permissions, on_delete: :delete_all)
      add :role_id, references(:roles, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:permissions_roles, [:permission_id])
    create index(:permissions_roles, [:role_id])
  end
end
