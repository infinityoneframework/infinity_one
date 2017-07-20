defmodule UccChat.PinnedMessage do
  use UccModel, schema: UccChat.Schema.PinnedMessage

  def count(message_id) do
    @schema
    |> where([s], s.message_id == ^message_id)
    |> select([s], count(s.id))
    |> @repo.one
  end

  def get_by_channel_id(channel_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> preload([:user, message: [:user]])
    |> order_by([m], desc: m.inserted_at)
    |> @repo.all
  end
end
