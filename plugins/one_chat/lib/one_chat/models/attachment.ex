defmodule OneChat.Attachment do
  use OneModel, schema: OneChat.Schema.Attachment
  alias OneChat.Schema.Message, as: MessageSchema

  def count(message_id) do
    @repo.one from a in @schema,
      where: a.message_id == ^message_id,
      select: count(a.id)
  end

  def get_attachments_by_channel_id(channel_id) do
    @repo.all from a in @schema,
      join: m in MessageSchema, on: a.message_id == m.id,
      order_by: [desc: m.timestamp],
      where: a.channel_id == ^channel_id
  end
end
