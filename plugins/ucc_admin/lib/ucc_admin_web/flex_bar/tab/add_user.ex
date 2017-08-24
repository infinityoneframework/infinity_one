defmodule UccAdminWeb.FlexBar.Tab.AddUser do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.TabBar
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView
  # alias UcxUcc.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_add_user",
      ~g"Add User",
      "icon-plus",
      FlexBarView,
      "add_user.html",
      20)
  end

  def args(socket, {user_id, _channel_id, _, _}, _) do
    user = Helpers.get_user! user_id
    {[
      user: user
    ], socket}
  end

end
