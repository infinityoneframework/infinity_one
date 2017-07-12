defmodule UccChat.PinnedMessage do
  use UccModel, schema: UccChat.Schema.PinnedMessage

  def count(message_id) do
    @schema
    |> where([s], s.message_id == ^message_id)
    |> select([s], count(s.id))
    |> @repo.one
  end
end
