defmodule UccAdminWeb.FlexBar.Tab.AddUser do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.TabBar
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView
  alias UcxUcc.Accounts
  # alias UcxUcc.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_add_user",
      ~g"Add User",
      "icon-plus",
      FlexBarView,
      "admin_new_user.html",
      20, [
        model: Accounts.User,
        get: {__MODULE__, :get_user},
        prefix: "user",
        changeset: {Accounts, :create_user}
      ])
  end

  def args(socket, {_user_id, _channel_id, _, _}, _) do
    user = Accounts.preload_schema %Accounts.User{}, :roles

    assigns =
      socket
      |> Rebel.get_assigns()
      |> Map.put(:user, user)
      |> Map.put(:resource_key, :user)

    Rebel.put_assigns(socket, assigns)

    {[
      current_user: Helpers.get_user!(socket.assigns.user_id),
      changeset: Accounts.change_user(user),
      user: nil,
      channel_id: nil,
      user_info: %{admin: true}
    ], socket}
  end

  def get_user(_) do
    %Accounts.User{}
  end

  def notify_update_success(socket, tab, sender, opts) do
    role = Accounts.get_role_by_name sender["form"]["user[roles]"]
    user = Accounts.get_by_username sender["form"]["user[username]"]
    Accounts.create_user_role %{user_id: user.id, role_id: role.id}
    socket
  end
end
