defmodule InfinityOne.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias InfinityOne.Accounts.{Role, User, UserRole}
  alias InfinityOne.Permissions.{Permission, PermissionRole}

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

  def default_roles, do: [
    admin: :global,
    moderator: :rooms,
    owner: :rooms,
    user: :global,
    bot: :global,
    guest: :global,
    "p-moderator": :pages,
    "p-owner": :pages,
  ]

  def scopes, do: ~w(global rooms pages)
  def scopes_list, do: Enum.map(scopes(), & {&1 |> String.capitalize() |> String.to_atom(), &1})

  def default_role_names do
    Enum.map(default_roles(), & &1 |> elem(0) |> to_string)
  end
end
