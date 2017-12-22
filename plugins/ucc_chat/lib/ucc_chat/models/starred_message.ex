defmodule UccChat.StarredMessage do
  use UccModel, schema: UccChat.Schema.StarredMessage

  def count(user_id, message_id, channel_id) do
    @schema
    |> where([s], s.user_id == ^user_id and
      s.message_id == ^message_id and
      s.channel_id == ^channel_id)
    |> select([s], count(s.id))
    |> @repo.one
  end

  def get_by_channel_id_and_user_id(channel_id, user_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id and m.user_id == ^user_id)
    |> preload([:user, message: [:user]])
    |> order_by([m], desc: m.inserted_at)
    |> @repo.all
  end
end
