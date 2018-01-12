defmodule UccChat.Schema.PinnedMessage do
  use UccChat.Shared, :schema

  alias UccChat.Schema.{Message, Channel}

  schema "pinned_messages" do
    belongs_to :message, Message
    belongs_to :channel, Channel

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
    |> unique_constraint(:message_id, name: :pinned_messages_channel_id_message_id)
  end
end
