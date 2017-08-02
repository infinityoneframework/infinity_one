defmodule UccChatWeb.FlexBar.Tab.UserInfo do
  use UccChatWeb.FlexBar.Helpers

  alias UccChat.{Channel, Direct}
  alias UcxUcc.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[direct],
      "user-info",
      ~g"User Info",
      "icon-user",
      View,
      "user_card.html",
      30)
  end

  def args(socket, user_id, channel_id, _, _) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id)
    direct = Direct.get_by user_id: user_id, channel_id: channel_id

    user = Helpers.get_user_by_name(direct.users)
    user_info = user_info(channel, direct: true)
    {[
      user: user,
      current_user: current_user,
      channel_id: channel_id,
      user_info: user_info
    ], socket}
  end
end

