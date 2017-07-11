defmodule UccChat.Mention do
  use UccModel, schema: UccChat.Schema.Mention

  def count(channel_id, user_id) do
    from m in @schema,
      where: m.user_id == ^user_id and m.channel_id == ^channel_id,
      select: count(m.id)
  end
end
