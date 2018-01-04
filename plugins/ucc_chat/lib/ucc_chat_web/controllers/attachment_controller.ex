defmodule UccChatWeb.AttachmentController do
  use UccChatWeb, :controller

  # alias UccChat.{Channel, User, Direct, ChannelService}
  alias UccChatWeb.RoomChannel.Attachment

  require Logger

  def create(conn, params) do
    # Logger.warn "attachment params: #{inspect params}"
    case Attachment.insert_attachment params do
      {:ok, _attachment, _message} ->
        render conn, "success.json", %{}
      {:error, _changeset} ->
        render conn, "error.json", %{}
      _other ->
        render conn, "success.json", %{}
    end
  end

end
