defmodule UccChat.Web.UiChannel do
  use Rebel.Channel, name: "ui", controllers: [
    UccChat.Web.ChannelController,
  ]
  import Rebel.Core
  import Rebel.Query

  def open_room(socket, sender) do
    socket
  end

  def test(socket, sender) do
    socket
  end

  def start_video_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.warn "start video curr_id: #{current_user_id}, user_id: #{user_id}"
  end

  def start_audio_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.warn "start audio curr_id: #{current_user_id}, user_id: #{user_id}"
  end
end
