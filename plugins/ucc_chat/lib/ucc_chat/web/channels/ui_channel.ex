defmodule UccChat.Web.UiChannel do

  use UccLogger
  use Rebel.Channel, name: "ui", controllers: [
    UccChat.Web.ChannelController,
  ]

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import Rebel.Browser, warn: false

  alias UccChat.Flex, warn: false
  use UcxUcc.UccPubSub

  access_session [:current_user_id]

  def join(event, payload, socket) do
    trace "join", payload, inspect(socket.assigns)
    user_id = socket.assigns.user_id

    subscribe_callback "user:" <> user_id, "room:join",
      {UccUiFlexTab.FlexTabChannel, :room_join}
    subscribe_callback "user:" <> user_id, "new:subscription",
      {UccChat.Web.UserChannel, :new_subscription}
    subscribe_callback "user:" <> user_id, "delete:subscription",
      {UccChat.Web.UserChannel, :delete_subscription}

    super event, payload,
      UccUiFlexTab.FlexTabChannel.do_join(socket, event, payload)
  end

  def start_video_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.warn "start video curr_id: #{current_user_id}, user_id: #{user_id}"
    socket
  end

  def start_audio_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.warn "start audio curr_id: #{current_user_id}, user_id: #{user_id}"
    socket
  end

  def add_private(socket, sender) do
    trace "add_private", sender
    username = exec_js! socket, ~s{$('#{this(sender)}').parent().data('username')}
    redirect_to socket, "/direct/#{username}"
  end

  handle_callback("user:" <>  _user_id)

  defdelegate flex_tab_click(socket, sender),
    to: UccUiFlexTab.FlexTabChannel
  defdelegate flex_call(socket, sender),
    to: UccUiFlexTab.FlexTabChannel
  defdelegate flex_form(socket, sender),
    to: UccChat.Web.FlexBar.Form
  defdelegate flex_form_save(socket, sender),
    to: UccChat.Web.FlexBar.Form
  defdelegate flex_form_cancel(socket, sender),
    to: UccChat.Web.FlexBar.Form

end
