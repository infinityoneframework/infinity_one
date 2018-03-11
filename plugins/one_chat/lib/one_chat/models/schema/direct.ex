defmodule OneChat.Schema.Direct do
  use OneChat.Shared, :schema

  schema "directs" do
    field :users, :string
    belongs_to :user, InfinityOne.Accounts.User
    belongs_to :friend, InfinityOne.Accounts.User

    belongs_to :channel, OneChat.Schema.Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(user_id friend_id channel_id)a

  def model, do: OneChat.Direct
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
