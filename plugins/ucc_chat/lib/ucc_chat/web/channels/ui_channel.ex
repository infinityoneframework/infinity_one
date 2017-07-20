defmodule UccChat.Web.UiChannel do
  use Rebel.Channel, name: "ui", controllers: [
    UccChat.Web.ChannelController,
  ]

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false

  alias UccChat.Flex, warn: false

  def join(event, payload, socket) do
    super event, payload,
      UccUiFlexTab.FlexTabChannel.do_join(socket, event, payload)
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

  defdelegate flex_tab_click(socket, sender),
    to: UccUiFlexTab.FlexTabChannel
  defdelegate flex_call(socket, sender),
    to: UccUiFlexTab.FlexTabChannel
  defdelegate flex_tab_item_click(socket, sender),
    to: UccUiFlexTab.FlexTabChannel
end
