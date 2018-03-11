defmodule OneChat.Schema.PinnedMessage do
  use OneChat.Shared, :schema

  alias OneChat.Schema.{Message, Channel}
  alias InfinityOne.OnePubSub

  require Logger

  schema "pinned_messages" do
    belongs_to :message, Message
    belongs_to :channel, Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(message_id channel_id)a

  def model, do: OneChat.PinnedMessage

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:message_id, name: :pinned_messages_channel_id_message_id)
    |> prepare_changes(&prepare_notify/1)
  end

  defp prepare_notify(%{action: :insert} = changeset) do
    channel_id = changeset.changes[:channel_id]
    OnePubSub.broadcast "pin:insert", "channel:#{channel_id}" ,
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(%{action: :delete} = changeset) do
    channel_id = changeset.data.channel_id
    OnePubSub.broadcast "pin:delete", "channel:#{channel_id}" ,
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(changeset) do
    changeset
  end
end
