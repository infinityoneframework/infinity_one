defmodule UccChat.AttachmentService do
  use UccChat.Shared, :service

  alias UccChat.{Attachment, Message}
  alias UccChatWeb.RoomChannel
  alias Ecto.Multi

  require Logger

  def insert_attachment(params) do
    message_params = %{channel_id: params["channel_id"], body: "", sequential: false, user_id: params["user_id"]}
    params = Map.delete params, "user_id"
    multi =
      Multi.new
      |> Multi.insert(:message, Message.change(message_params))
      |> Multi.run(:attachment, &do_insert_attachment(&1, params))

    case Repo.transaction(multi) do
      {:ok, %{message: message}} = ok ->
        RoomChannel.broadcast_message(message)
        ok
      error ->
        error
    end
  end

  defp do_insert_attachment(%{message: %{id: id} = message}, params) do
    params
    |> Map.put("message_id", id)
    |> Attachment.create()
    |> case do
      {:ok, attachment} ->
        {:ok, %{attachment: attachment, message: message}}
      error -> error
    end
  end

  def delete_attachment(%UccChat.Schema.Attachment{} = attachment) do
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
