defmodule UccChat.MessageCogService do
  # import Ecto.Query

  alias UccChat.{Message, StarredMessage, PinnedMessage}
  alias UccChatWeb.{MessageView, FlexBarView}

  alias UcxUcc.Repo
  alias UccChat.ServiceHelpers, as: Helpers
  # alias UccChat.Schema.StarredMessage, as: StarredMessageSchema

  require Logger

  def handle_in("open", %{"flex_tab" => true}, _) do
    html =
      "flex_cog.html"
      |> FlexBarView.render()
      |> Helpers.safe_to_string
    {nil, %{html: html}}
  end

  def handle_in("open", %{"user_id" => user_id, "channel_id" => channel_id} = msg, _) do
    message_id = get_message_id msg["message_id"]
    star_count = StarredMessage.count(user_id, message_id, channel_id)
    pin_count = PinnedMessage.count(message_id)
    opts = [starred: star_count > 0, pinned: pin_count > 0]
    Logger.debug "MessageCogService: open, msg: #{inspect msg}, message_id: #{inspect message_id}"

    html =
      "message_cog.html"
      |> MessageView.render(opts: opts)
      |> Helpers.safe_to_string

    {nil, %{html: html}}
  end

  def handle_in("star-message", %{"user_id" => user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    star = StarredMessage.create!(%{message_id: id, user_id: user_id,
      channel_id: channel_id})
    Logger.debug "star: #{inspect star}"
    {"update:starred", %{}}
  end
  def handle_in("unstar-message", %{"user_id" => user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    StarredMessage.delete! StarredMessage.get_by(user_id: user_id,
      message_id: id, channel_id: channel_id)
    {"update:starred", %{}}
  end

  def handle_in("pin-message", %{"user_id" => _user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    message = Repo.get Message, id
    pin = PinnedMessage.create!(%{message_id: id, user_id: message.user_id,
      channel_id: channel_id})
    Logger.debug "pin: #{inspect pin}"
    {"update:pinned", %{}}
  end

  def handle_in("unpin-message", %{"user_id" => _user_id, "channel_id" => _channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    PinnedMessage.delete PinnedMessage.get_by(message_id: id)
    {"update:pinned", %{}}
  end
  # def handle_in("edit-message", %{"user_id" => _user_id, "channel_id" => _channel_id}, _socket) do

  # end
  def handle_in("delete-message", msg, socket) do
    Logger.warn "delete-message"
    UccChatWeb.MessageChannelController.delete socket, msg
  end

  # def handle_in("jump-to-message", msg, _) do
  #   {nil, %{}}
  # end

  defp get_message_id(id), do: id
end
