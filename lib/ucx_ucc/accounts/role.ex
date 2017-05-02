defmodule UcxUcc.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.Role


  schema "accounts_roles" do
    field :description, :string
    field :name, :string
    field :scope, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, [:name, :scope, :description])
    |> validate_required([:name, :scope, :description])
  end
end
