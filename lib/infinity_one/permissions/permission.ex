defmodule InfinityOne.Permissions.Permission do
  use Ecto.Schema
  import Ecto.Changeset
  alias InfinityOne.Accounts.{Role}
  alias InfinityOne.Permissions.{PermissionRole, Permission}

  schema "permissions" do
    field :name, :string

    many_to_many :roles, Role, join_through: PermissionRole
  end

  @doc false
  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
