defmodule OneChatWeb.AttachmentController do
  @moduledoc """
  Handle new attachment controller actions.
  """
  use OneChatWeb, :controller

  alias OneChat.Message

  @doc """
  Post a new attachment upload.
  """
  def create(conn, params) do
    %{
      channel_id: params["channel_id"],
      user_id: params["user_id"],
      attachments: [params]
    }
    |> Message.create()
    |> case do
      {:ok, _message} ->
        render conn, "success.json", %{}
      {:error, _cs} ->
        render conn, "error.json", %{}
      {:error, _, _cs} ->
        render conn, "error.json", %{}
    end
  end
end
