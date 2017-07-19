defmodule UccChat.Web.UiChannel do
  use Rebel.Channel, name: "ui", controllers: [
    UccChat.Web.ChannelController,
  ]

  import Rebel.Core
  import Rebel.Query

  alias UccChat.Chat
  alias UccChat.Flex

  # def handle_out("room:join", payload, socket) do
  #   Logger.warn inspect(payload, label: "******* room:join payload *********")
  #   %{room: room} = payload
  #   channel = Chat.get_channel_by_name room
  #   {:noreply, socket |> assign(:room, room) |> assign(:channel_id, channel.id)}
  # end

  # def handle_out("room:leave" = _ev, payload, socket) do
  #   Logger.warn inspect(payload, label: "******* room:leave payload *********")
  #   %{room: room} = payload
  #   {:noreply, socket |> assign(:room, nil) |> assign(:channel_id, nil)}
  # end
  def join(event, payload, socket) do
    socket =
      socket
      |> UccUiFlexTab.FlexTabChannel.do_join(event, payload)
    super event, payload, socket
  end

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

  defdelegate flex_tab_click(socket, sender), to: UccUiFlexTab.FlexTabChannel
  defdelegate flex_call(socket, sender), to: UccUiFlexTab.FlexTabChannel
  # def flex_tab_click(socket, sender) do
  #   UccUiFlexTab.FlexTabChannel.flex_tab_click socket, sender
  # end
end
