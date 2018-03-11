defmodule OneChat.AttachmentService do
  use OneChat.Shared, :service

  alias OneChat.{Attachment}

  require Logger

  def delete_attachment(%OneChat.Schema.Attachment{} = attachment) do
    Logger.warn "deprecated"
    case Attachment.delete attachment do
      {:ok, _} = res ->
        path = OneChat.File.storage_dir(attachment)
        File.rm_rf path
        res
      error -> error
    end
  end

  # defp broadcast_message(message) do
  #   channel = Channel.get message.channel_id
  #   html =
  #     message
  #     |> Repo.preload(MessageService.preloads())
  #     |> MessageService.render_message
  #   MessageService.broadcast_message(message.id, channel.name, message.user_id, html)
  # end

  def count(message_id) do
    Attachment.count message_id
  end

  def allowed?(channel) do
    OneSettings.file_uploads_enabled() && ((channel.type != 2) || OneSettings.dm_file_uploads())
  end
end
