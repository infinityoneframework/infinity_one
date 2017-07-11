defmodule UccChat.Schema.Mute do
  use UccChat.Shared, :schema

  alias UcxUcc.Accounts.User
  alias UccChat.Schema.{Channel}

  schema "muted" do
    belongs_to :user, User
    belongs_to :channel, Channel

    timestamps()
  end

  @fields ~w(user_id channel_id)a
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:user_id, name: :muted_user_id_channel_id_index)
  end
end
