defmodule UccChat.AttachmentService do
  use UccChat.Shared, :service

  alias UccChat.{Attachment}

  require Logger

  def delete_attachment(%UccChat.Schema.Attachment{} = attachment) do
    Logger.warn "deprecated"
    case Attachment.delete attachment do
      {:ok, _} = res ->
        path = UccChat.File.storage_dir(attachment)
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
    UccSettings.file_uploads_enabled() && ((channel.type != 2) || UccSettings.dm_file_uploads())
  end
end
