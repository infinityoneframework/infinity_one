defmodule UccChat.StaredMessage do
  use UccModel, schema: UccChat.Schema.StaredMessage

  def count(user_id, message_id, channel_id) do
    @schema
    |> where([s], s.user_id == ^user_id and
      s.message_id == ^message_id and
      s.channel_id == ^channel_id)
    |> select([s], count(s.id))
    |> @repo.one
  end
end
