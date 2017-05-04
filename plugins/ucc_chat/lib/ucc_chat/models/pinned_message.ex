defmodule UccChat.PinnedMessage do
  use UccChat.Shared, :schema

  schema "pinned_messages" do
    belongs_to :message, UccChat.Message
    belongs_to :channel, UccChat.Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(message_id channel_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
