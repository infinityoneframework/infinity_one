defmodule UccChat.MessageCogService do
  # import Ecto.Query

  alias UccChat.{Message, StaredMessage, PinnedMessage}
  alias UccChatWeb.{MessageView, FlexBarView}

  alias UcxUcc.Repo
  alias UccChat.ServiceHelpers, as: Helpers
  # alias UccChat.Schema.StaredMessage, as: StaredMessageSchema

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
    star_count = StaredMessage.count(user_id, message_id, channel_id)
    pin_count = PinnedMessage.count(message_id)
    opts = [stared: star_count > 0, pinned: pin_count > 0]
    Logger.warn "MessageCogService: open, msg: #{inspect msg}, message_id: #{inspect message_id}"

    html =
      "message_cog.html"
      |> MessageView.render(opts: opts)
      |> Helpers.safe_to_string

    {nil, %{html: html}}
  end

  def handle_in("star-message", %{"user_id" => user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    star = StaredMessage.create!(%{message_id: id, user_id: user_id,
      channel_id: channel_id})
    Logger.warn "star: #{inspect star}"
    {"update:stared", %{}}
  end
  def handle_in("unstar-message", %{"user_id" => user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    StaredMessage.delete! StaredMessage.get_by(user_id: user_id,
      message_id: id, channel_id: channel_id)
    {"update:stared", %{}}
  end

  def handle_in("pin-message", %{"user_id" => _user_id, "channel_id" => channel_id} = msg, _) do
    id = get_message_id msg["message_id"]
    message = Repo.get Message, id
    pin = PinnedMessage.create!(%{message_id: id, user_id: message.user_id,
      channel_id: channel_id})
    Logger.warn "pin: #{inspect pin}"
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
    UccChatWeb.MessageChannelController.delete socket, msg
  end

  # def handle_in("jump-to-message", msg, _) do
  #   {nil, %{}}
  # end

  defp get_message_id(id), do: id
end
