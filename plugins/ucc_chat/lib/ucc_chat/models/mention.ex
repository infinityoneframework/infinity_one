defmodule UccChat.Mention do
  use UccModel, schema: UccChat.Schema.Mention

  def count(channel_id, user_id) do
    from m in @schema,
      where: m.user_id == ^user_id and m.channel_id == ^channel_id,
      select: count(m.id)
  end

  def get_by_user_id_and_channel_id(user_id, channel_id) do
    @schema
    |> where([m], m.user_id == ^user_id and m.channel_id == ^channel_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user, message: :user])
    |> @repo.all
  end
end
