defmodule UccChat.Schema.Direct do
  use UccChat.Shared, :schema

  schema "directs" do
    field :users, :string
    belongs_to :user, UcxUcc.Accounts.User
    belongs_to :friend, UcxUcc.Accounts.User

    belongs_to :channel, UccChat.Schema.Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(user_id friend_id channel_id)a

  def model, do: UccChat.Direct
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:users, name: :directs_user_id_friend_id_index)
  end

end
