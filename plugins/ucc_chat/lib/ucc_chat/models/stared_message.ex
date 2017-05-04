defmodule UccChat.StaredMessage do
  use UccChat.Shared, :schema

  schema "stared_messages" do
    belongs_to :user, UcxUcc.Accounts.User
    belongs_to :message, UccChat.Message
    belongs_to :channel, UccChat.Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(user_id message_id channel_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
