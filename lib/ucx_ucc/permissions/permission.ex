defmodule UcxUcc.Permissions.Permission do
  use Ecto.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.{Role}
  alias UcxUcc.Permissions.{PermissionRole, Permission}

  schema "permissions_permissions" do
    field :name, :string

    many_to_many :roles, Role, join_through: PermissionRole
  end

  @doc false
  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
