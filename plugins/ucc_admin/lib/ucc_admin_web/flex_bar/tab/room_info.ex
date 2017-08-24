# defmodule UccAdminWeb.FlexBar.Tab.RoomInfo do
#   use UccLogger
#   use UccChatWeb.FlexBar.Helpers

#   alias UcxUcc.TabBar
#   alias TabBar.Tab
#   alias UccAdminWeb.FlexBarView
#   alias UccChat.Channel
#   alias UcxUcc.UccPubSub
#   # alias UcxUcc.TabBar.Ftab

#   def add_buttons do
#     TabBar.add_button Tab.new(
#       __MODULE__,
#       ~w[admin_rooms],
#       "admin_room_info",
#       ~g"Room Info",
#       "icon-info-circled",
#       FlexBarView,
#       "room_info.html",
#       10)
#   end

#   def args(socket, user_id, channel_id, _, params) do
#     current_user = Helpers.get_user! user_id
#     channel = Channel.get!(channel_id) |> set_private()
#     changeset = Channel.change channel
#     editing = to_existing_atom(params["editing"])

#     assigns =
#       socket
#       |> Rebel.get_assigns()
#       |> Map.put(:channel, channel)
#       |> Map.put(:resource_key, :channel)

#     Rebel.put_assigns(socket, assigns)

#     {[
#       channel: settings_form_fields(channel, user_id),
#       current_user: current_user,
#       changeset: changeset,
#       editing: editing,
#       channel_type: channel.type], socket}
#   end

# end
