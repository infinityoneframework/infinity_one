defmodule UccChat.Web.UiChannel do

  # use UccLogger
  # use UcxUcc.UccPubSub
  # use Rebel.Channel, name: "ui", controllers: [
  #   UccChat.Web.ChannelController,
  # ]

  # import Rebel.Core, warn: false
  # import Rebel.Query, warn: false
  # import Rebel.Browser, warn: false

  # alias UccChat.{SideNavService, MessageService, Web.MasterView}
  # alias UccUiFlexTab.FlexTabChannel
  # alias UccChat.Web.FlexBar.Form

  # access_session [:current_user_id]

  # def join(event, payload, socket) do
  #   trace "join", payload, inspect(socket.assigns)
  #   user_id = socket.assigns.user_id

  #   subscribe_callback "user:" <> user_id, "room:join",
  #     {FlexTabChannel, :room_join}
  #   subscribe_callback "user:" <> user_id, "new:subscription",
  #     :new_subscription
  #   subscribe_callback "user:" <> user_id, "delete:subscription",
  #     :delete_subscription
  #   subscribe_callback "user:" <> user_id, "room:update",
  #     :room_update

  #   super event, payload, FlexTabChannel.do_join(socket, event, payload)
  # end

  # def start_video_call(socket, sender) do
  #   current_user_id = socket.assigns.user_id
  #   user_id = sender["dataset"]["id"]
  #   Logger.warn "start video curr_id: #{current_user_id}, user_id: #{user_id}"
  #   socket
  # end

  # def start_audio_call(socket, sender) do
  #   current_user_id = socket.assigns.user_id
  #   user_id = sender["dataset"]["id"]
  #   Logger.warn "start audio curr_id: #{current_user_id}, user_id: #{user_id}"
  #   socket
  # end

  # def add_private(socket, sender) do
  #   trace "add_private", sender
  #   username = exec_js! socket, ~s{$('#{this(sender)}').parent().data('username')}
  #   redirect_to socket, "/direct/#{username}"
  # end

  # handle_callback("user:" <>  _user_id)

  # defdelegate flex_tab_click(socket, sender),
  #   to: FlexTabChannel
  # defdelegate flex_call(socket, sender),
  #   to: FlexTabChannel
  # defdelegate flex_form(socket, sender),
  #   to: Form
  # defdelegate flex_form_save(socket, sender),
  #   to: Form
  # defdelegate flex_form_cancel(socket, sender),
  #   to: Form
  # defdelegate flex_form_toggle(socket, sender),
  #   to: Form

  # def new_subscription(_event, payload, socket) do
  #   channel_id = payload.channel_id
  #   user_id = socket.assigns.user_id

  #   socket
  #   |> update_rooms_list(user_id, channel_id)
  #   |> update_messages_header(true)
  # end

  # def delete_subscription(_event, payload, socket) do
  #   channel_id = payload.channel_id
  #   user_id = socket.assigns.user_id
  #   socket
  #   |> update_rooms_list(user_id, channel_id)
  #   |> update_message_box(user_id, channel_id)
  #   |> update_messages_header(false)
  # end

  # def room_update(_event, payload, socket) do
  #   trace "room_update", payload
  #   channel_id = payload.channel_id
  #   user_id = socket.assigns.user_id
  #   socket
  #   |> do_room_update(payload[:field], user_id, channel_id)
  #   |> broadcast_open_info_flex_box(user_id, channel_id)

  #   # broadcast info box on user channel
  #   # socket
  #   # |> update_rooms_list(user_id, channel_id)
  #   # |> update_message_box(user_id, channel_id)
  #   # |> update_messages_header(true)
  # end

  # defp do_room_update(socket, {:name, }, user_id, channel_id) do
  #   # broadcast message header on room channel
  #   # broadcast room entry on user channel
  #   socket
  # end
  # defp do_room_update(socket, {:topic, }, user_id, channel_id) do
  #   # breoadcast message header on room channel
  #   socket
  # end
  # defp do_room_update(socket, {:type, }, user_id, channel_id) do
  #   # breoadcast message header on room channel
  #   # broadcast room entry on user channel
  #   # broadcast message box on room channel
  #   socket
  # end
  # defp do_room_update(socket, {:read_only, }, user_id, channel_id) do
  #   # broadcast message box on room channel
  #   socket
  # end
  # defp do_room_update(socket, {:archived, }, user_id, channel_id) do
  #   # broadcast room entry on user channel
  #   # broadcast message box on room channel
  #   socket
  # end
  # defp do_room_update(socket, _field, _user_id, _channel_id) do
  #   socket
  # end

  # defp broadcast_open_info_flex_box(socket, user_id, channel_id) do
  #   # on user channel
  #   socket
  # end

  # defp update_rooms_list(socket, user_id, channel_id) do
  #   update socket, :html,
  #     set: SideNavService.render_rooms_list(channel_id, user_id),
  #     on: "aside.side-nav .rooms-list"
  #   socket
  # end

  # defp broadcast_rooms_list(socket, user_id, channel_id) do
  #   socket
  # end

  # defp update_message_box(socket, user_id, channel_id) do
  #   update socket, :html,
  #     set: MessageService.render_message_box(channel_id, user_id),
  #     on: ".room-container footer.footer"
  #   socket
  # end

  # defp update_messages_header(socket, show) do
  #   html = Phoenix.View.render_to_string MasterView, "favorite_icon.html",
  #     show: show, favorite: false
  #   async_js socket,
  #     ~s/$('section.messages-container .toggle-favorite').replaceWith('#{html}')/
  #   socket
  # end

end
