defmodule UccChat.Web.FlexBar.Tab.UserInfo do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.{Channel, Direct}

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[direct],
      id: "user-info",
      title: ~g"User Info",
      icon: "icon-user",
      view: View,
      template: "user_card.html",
      order: 30
    }
  end

  def args(user_id, channel_id, _, _) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id)
    direct = Direct.get_by user_id: user_id, channel_id: channel_id

    user = Helpers.get_user_by_name(direct.users)
    user_info = user_info(channel, direct: true)
    [user: user, current_user: current_user, channel_id: channel_id,
     user_info: user_info]
  end
end

