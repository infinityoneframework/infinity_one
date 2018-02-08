defmodule UccChatWeb.RoomChannel.Attachment do
  # TODO: Remove this module
  # alias UccChat.{Attachment, Message}
  # alias UccChatWeb.RoomChannel
  # alias Ecto.Multi
  # alias UcxUcc.Repo

  # require Logger

  # def insert_attachment(params) do
  #   # Logger.warn inspect(params)

  #   # TODO: I don't like this approach since it sends so all channels for the
  #   #       room. We should be doing this through a rebel update or the
  #   #       user's channel.
  #   RoomChannel.new_attachment(params["room"], params)
  # end

  # def create(user_id, channel_id, params) do
  #   message_params = %{channel_id: channel_id, body: "", sequential: false, user_id: user_id}
  #   params = Map.delete params, "user_id"

  #   multi =
  #     Multi.new
  #     |> Multi.insert(:message, Message.change(message_params))
  #     |> Multi.run(:attachment, &do_insert_attachment(&1, params))

  #   case Repo.transaction(multi) do
  #     {:ok, %{message: message}} ->
  #       {:ok, message}
  #     error ->
  #       error
  #   end
  # end

  # defp do_insert_attachment(%{message: %{id: id} = message}, params) do
  #   params
  #   |> Map.put("message_id", id)
  #   |> Attachment.create()
  #   |> case do
  #     {:ok, attachment} ->
  #       {:ok, %{attachment: attachment, message: message}}
  #     error -> error
  #   end
  # end
end
