defmodule UccAdminWeb.FlexBar.Tab.UserInfo do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.{TabBar, Hooks, Accounts}
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView
  # alias UcxUcc.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_user_info",
      ~g"User Info",
      "icon-user",
      FlexBarView,
      "admin_edit_user.html",
      30)
  end

  def args(socket, {user_id, _channel_id, other, sender}, params) do

    user =
      if name = sender["dataset"]["name"] do
        Accounts.get_by_user username: name, preload: Hooks.user_preload([])
      else
        nil
      end
    {[
      current_user: Helpers.get_user!(user_id),
      user: user,
    ], socket}
  end

end
