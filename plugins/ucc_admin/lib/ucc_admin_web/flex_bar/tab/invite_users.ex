defmodule UccAdminWeb.FlexBar.Tab.InviteUsers do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.TabBar
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView
  alias UccAdmin.AdminService
  # alias UcxUcc.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_invite_users",
      ~g"Inivite Users",
      "icon-paper-plane",
      FlexBarView,
      "admin_invite_users.html",
      10)
  end

    # html =
    #   "admin_invite_users.html"
    #   |> FlexBarView.render(user: current_user, channel_id: nil, user_info: %{admin: true},
    #      invite_emails: [], error_emails: [], pending_invitations: get_pending_invitations())
    #   |> safe_to_string
  def args(socket, {user_id, _channel_id, _, _}, _) do
    user = Helpers.get_user! user_id
    {[
      user: user,
      channel_id: nil,
      user_info: %{admin: true},
      error_emails: [],
      pending_invitations: AdminService.get_pending_invitations(),
      invite_emails: []], socket}
  end

  def invite_users(socket, sender) do
    Logger.info inspect(sender)
    socket
  end

end
