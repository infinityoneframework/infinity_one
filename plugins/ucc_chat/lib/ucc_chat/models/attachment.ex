defmodule UccChat.Attachment do
  use UccModel, schema: UccChat.Schema.Attachment

  def count(message_id) do
    @repo.one from a in @schema,
      where: a.message_id == ^message_id,
      select: count(a.id)
  end
end
