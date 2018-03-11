defmodule InfinityOne.Permissions.PermissionRole do
  use Ecto.Schema
  import Ecto.Changeset
  alias InfinityOne.Accounts.{Role}
  alias InfinityOne.Permissions.{PermissionRole, Permission}


  schema "permissions_roles" do
    belongs_to :permission, Permission
    belongs_to :role, Role

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%PermissionRole{} = permission_role, attrs) do
    permission_role
    |> cast(attrs, [:permission_id, :role_id])
    |> validate_required([:permission_id, :role_id])
  end
end
