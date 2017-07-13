defmodule UcxUcc.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.{Query, Changeset}, warn: false

  @scopes ~w(global rooms)

  schema "users_roles" do
    field :scope, :binary_id, default: nil  # id of room
    belongs_to :user, UcxUcc.Accounts.User, type: :binary_id
    belongs_to :role, UcxUcc.Accounts.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:scope, :user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> validate_inclusion(:scope, @scopes)
  end
end
