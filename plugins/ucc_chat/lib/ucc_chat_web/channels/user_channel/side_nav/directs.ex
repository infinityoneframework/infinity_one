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
    with user when not is_nil(user) <- UccChat.ServiceHelpers.get_user_by_name(username),
         user_id <- socket.assigns.user_id,
         false <- user.id == user_id do
      direct =
        case get_direct(user_id, username) do
          nil ->
            ChannelService.add_direct(username, user_id, nil)
            get_direct(user_id, username)
          direct ->
            direct
        end
      Channels.open_room socket, assigns.room, direct.channel.name, direct.users
    else
      _ ->
        Client.toastr socket, :error, ~g(Could not open that direct channel)
    end
    socket
  end

  defp get_direct(user_id, name) do
    Direct.get_by user_id: user_id, users: name, preload: [:channel]
  end
end
