defmodule UcxUcc.Accounts.Account do
  use Unbrella.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.Account
  alias UcxUcc.Accounts.User


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%Account{} = account, attrs \\ %{}) do
    account
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end

  import Ecto.Query

  def get(user_id) do
    from u in User,
      join: a in Account,
      on: u.id == a.user_id,
      where: u.id == ^user_id,
      select: a
  end
end
