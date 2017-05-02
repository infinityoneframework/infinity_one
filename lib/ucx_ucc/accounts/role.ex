defmodule UcxUcc.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.{Role, User, UserRole}


  schema "accounts_roles" do
    field :description, :string
    field :name, :string
    field :scope, :string

    many_to_many :users, User, join_through: UserRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name, :scope, :description])
    |> validate_required([:name])
  end
end
