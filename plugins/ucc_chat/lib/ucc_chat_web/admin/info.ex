defmodule UccChatWeb.Admin.Page.Info do
  use UccAdmin.Page

  alias UccChat.{Message, Channel, UserService}

  def add_page do
    new("admin_info", __MODULE__, ~g(Info), UccChatWeb.AdminView, "info.html", 10)
  end

  def args(page, user, _sender, socket) do
    # Logger.warn "..."
    total = UserService.total_users_count()
    online = UserService.online_users_count()

    usage = [
      %{title: ~g"Total Users", value: total},
      %{title: ~g"Online Users", value: online},
      %{title: ~g"Offline Users", value: total - online},
      %{title: ~g"Total Rooms", value: Channel.get_total_rooms()},
      %{title: ~g"Total Channels", value: Channel.get_total_channels()},
      %{title: ~g"Total Private Groups", value: Channel.get_total_private()},
      %{title: ~g"Total Direct Message Rooms", value: Channel.get_total_direct()},
      %{title: ~g"Total Messages", value: Message.get_total_count()},
      %{title: ~g"Total Messages in Channels", value: Message.get_total_channels()},
      %{title: ~g"Total in Private Groups", value: Message.get_total_private()},
      %{title: ~g"Total in Direct Messages", value: Message.get_total_direct()},
    ]

    {[
      user: user,
      info: [usage: usage],
    ], user, page, socket}
  end

end
