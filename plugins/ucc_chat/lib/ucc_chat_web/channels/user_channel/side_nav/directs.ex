defmodule UccChatWeb.UserChannel.SideNav.Directs do
  # import Rebel.Core
  # import Phoenix.View, only: [render_to_string: 3]
  import UcxUccWeb.Gettext

  # alias UcxUccWeb.Query
  alias UccChat.{ChannelService, Direct}
  alias UccChatWeb.{RebelChannel.Client}
  # alias UcxUcc.Accounts
  alias UccChatWeb.UserChannel.SideNav.Channels

  require Logger

  def open_direct(socket, sender) do
    open_direct_channel(socket, sender["dataset"]["direct"])
  end

  def open_direct_channel(socket, username) do
    assigns = socket.assigns
    with friend when not is_nil(friend) <- UccChat.ServiceHelpers.get_user_by_name(username),
         user_id <- socket.assigns.user_id,
         false <- friend.id == user_id do
      direct =
        case get_direct(user_id, friend.id) do
          nil ->
            ChannelService.add_direct(friend, user_id, nil)
            get_direct(user_id, friend.id)
          direct ->
            direct
        end
      Channels.open_room socket, assigns.room, direct.channel.name, friend.username
    else
      _ ->
        Client.toastr socket, :error, ~g(Could not open that direct channel)
    end
    socket
  end

  defp get_direct(user_id, friend_id) do
    Direct.get_by user_id: user_id, friend_id: friend_id, preload: [:channel]
  end
end
