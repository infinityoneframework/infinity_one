defmodule UccAdminWeb.FlexBar.Tab.UserInfo do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  import UccChat.ServiceHelpers, only: [safe_to_string: 1]

  alias UccChat.{Channel, Direct}
  alias UcxUcc.{Accounts, TabBar.Tab}
  alias UccChatWeb.Client
  alias UccChatWeb.AdminView

  alias UcxUcc.{TabBar, Hooks}
  alias UccAdminWeb.FlexBarView

  @roles_preload [:roles, user_roles: :role]

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_user_info",
      ~g"User Info",
      "icon-user",
      FlexBarView,
      "admin_user_card.html",
      30,
      [
        model: Accounts.User,
        get: {Accounts, :get_user, [[preload: [phone_numbers: [:label]]]]},
        prefix: "user"
      ])
  end

  def args(socket, {user_id, channel_id, _, sender}, _) do
    form = sender["form"]
    current_user = Helpers.get_user! user_id
    user =
      if name = sender["dataset"]["name"] || form["id"] do
        Accounts.get_by_user username: name, preload: Hooks.user_preload([:roles, user_roles: :role, phone_numbers: [:label]])
      else
        nil
      end

    {[
      user: user,
      current_user: current_user,
      channel_id: nil,
      user_info: %{admin: true}
    ], socket}
  end

  def edit_args(socket, user_id) do
    user = Accounts.get_user user_id, preload: Hooks.user_preload([phone_numbers: [:label]])

    assigns =
      socket
      |> Rebel.get_assigns()
      |> Map.put(:user, user)
      |> Map.put(:resource_key, :user)

    Rebel.put_assigns(socket, assigns)

    [
      current_user: Helpers.get_user!(socket.assigns.user_id),
      changeset: Accounts.change_user(user),
      user: user,
    ]
  end

  def notify_cancel(socket, _tab, _sender) do
    Client.send_js socket, ~s/$('.flex-nav li.active .admin-link').click()/
    socket
  end

  def make_admin(socket, sender) do
    user = Accounts.get_user(sender["dataset"]["userId"], preload: @roles_preload)
    if Accounts.has_role? user, "admin" do
      Client.toastr! socket, :error, ~g(User is already an admin)
    else
      case Accounts.add_role_to_user(user, "admin") do
        {:ok, _} ->
          html =
            user.id
            |> Accounts.get_user(preload: @roles_preload)
            |> AdminView.render_user_action_button("admin")
            |> safe_to_string

          socket
          |> Client.replace_with(".user-view button.change-admin", html)
          |> Client.toastr!(:success, ~g(Add admin role successful))
        _ ->
          Client.toastr! socket, :error, ~g(Problem adding admin role to user)
      end
    end
    socket
  end

  def remove_admin(socket, sender) do
    user = Accounts.get_user(sender["dataset"]["userId"], preload: @roles_preload)
    if Accounts.has_role? user, "admin" do
      case Accounts.delete_users_role(user, "admin") do
        :ok ->
          html = action_button_html user.id, "admin"

          socket
          |> Client.replace_with(".user-view button.change-admin", html)
          |> Client.toastr!(:success, ~g(Remove admin role successful))
        _ ->
          Client.toastr! socket, :error, ~g(Problem removing admin role from user)
      end
    else
      Client.toastr! socket, :error, ~g(User is not an admin)
    end
    socket
  end

  defp action_button_html(user_id, action) do
    user_id
    |> Accounts.get_user(preload: @roles_preload)
    |> AdminView.render_user_action_button(action)
    |> safe_to_string
  end

  def activate(socket, sender) do
    user = Accounts.get_user(sender["dataset"]["userId"], preload: @roles_preload)
    if user.active do
      Client.toastr! socket, :error, ~g(User is aleady active)
    else
      user
      |> Accounts.activate_user()
      |> Accounts.update_user(%{active: true})
      |> case do
        {:ok, _} ->
          html = action_button_html user.id, "activate"

          socket
          |> Client.replace_with(".user-view button.change-active", html)
          |> Client.toastr!(:success, ~g(User was activated successfully))
        _ ->
          Client.toastr! socket, :error, ~g(Problem activating user)
      end
    end
    socket
  end

  def deactivate(socket, sender) do
    user = Accounts.get_user(sender["dataset"]["userId"], preload: @roles_preload)
    if user.active do
      user
      |> Accounts.deactivate_user()
      |> Accounts.update_user(%{active: false})
      |> case do
        {:ok, _} ->
          html = action_button_html user.id, "activate"

          socket
          |> Client.replace_with(".user-view button.change-active", html)
          |> Client.toastr!(:success, ~g(User was deactivated successfully))
        _ ->
          Client.toastr! socket, :error, ~g(Problem deactivating user)
      end
    else
      Client.toastr! socket, :error, ~g(User is not active)
    end
    socket
  end

  def edit_user(socket, sender) do
    bindings = edit_args socket, sender["dataset"]["userId"]

    html = Phoenix.View.render_to_string FlexBarView, "admin_edit_user.html", bindings
    Rebel.Query.update socket, :html, set: html, on: ".flex-tab-main"

    socket
  end

  def delete(socket, sender) do
    Logger.warn inspect(sender)
    Client.toastr! socket, :warning, ~s(Not yet implemented)
    # TODO: Need to implement a conformation dialog
    # current_user = Accounts.get_user socket.assigns.user_id, preload: @roles_preload
    # if Permission.has_permission?(current_user, "delete-user") do
    #   sender["dataset"]["userId"]
    #   |> Accounts.get_user(preload: @roles_preload)
    #   |> Accounts.delete_user()
    #   Client.send_js socket, ~s/$('.flex-nav li.active .admin-link').click()/
    #   Client.toastr!(socket, :success, ~g(User was deleted successfully))
    # end
    socket
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
