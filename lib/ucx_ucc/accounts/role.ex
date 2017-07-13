defmodule UcxUcc.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.{Role, User, UserRole}
  alias UcxUcc.Permissions.{Permission, PermissionRole}

  schema "roles" do
    field :description, :string
    field :name, :string
    field :scope, :string

    many_to_many :users, User, join_through: UserRole
    many_to_many :permissions, Permission, join_through: PermissionRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name, :scope, :description])
    |> validate_required([:name])
  end
end
