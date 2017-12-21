defmodule UccAdminWeb.FlexBar.Tab.UserInfo do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.{TabBar, Hooks, Accounts}
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_user_info",
      ~g"User Info",
      "icon-user",
      FlexBarView,
      "admin_edit_user.html",
      30,
      [
        model: Accounts.User,
        get: {Accounts, :get_user, [[preload: [phone_numbers: [:label]]]]},
        prefix: "user"
      ])
  end

  def args(socket, {user_id, _channel_id, _other, sender}, _params) do

    exec_js socket, set_active_js(sender)

    # Logger.error "sender: " <> inspect(sender)
    form = sender["form"] || %{}
    # Logger.error "id #{form["id"]}, form: " <> inspect(form)

    {user, changeset} =
      if name = sender["dataset"]["name"] || form["id"] do
        user = Accounts.get_by_user username: name, preload: Hooks.user_preload([phone_numbers: [:label]])

        assigns =
          socket
          |> Rebel.get_assigns()
          |> Map.put(:user, user)
          |> Map.put(:resource_key, :user)

        Rebel.put_assigns(socket, assigns)
        {user, Accounts.change_user(user)}
      else
        {nil, Accounts.change_user(%{})}
      end
    {[
      current_user: Helpers.get_user!(user_id),
      changeset: changeset,
      user: user,
    ], socket}
  end

  def notify_update_success(socket, tab, sender, _opts, client \\ UccChatWeb.Client)

  def notify_update_success(socket, %{id: "admin_user_info"}, _sender, _opts, client) do
    client.send_js socket, click_users_link_js()
    socket
  end

  def notify_update_success(socket, _tab, _sender, _opts, _) do
    # Logger.info "tab: #{inspect tab}, sender: #{inspect sender}"
    socket
  end

  def notify_cancel(socket, _tab, _sender, client \\ UccChatWeb.Client) do
    client.send_js socket, click_users_link_js()
    socket
  end

  defp click_users_link_js, do: """
    var link = $('.flex-nav li.active a.admin-link[data-id="admin_users"]');
    if (link) {
      link.click();
    }
    """

  defp set_active_js(sender), do: """
   $('.flex-tab-main-content tr').removeClass('active');
   $('#{this(sender)}').addClass('active');
    """ |> String.replace("\n", "")

end
