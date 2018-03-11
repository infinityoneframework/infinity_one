defmodule OneAdminWeb.FlexBar.Tab.UserInfo do
  use OneLogger
  use OneChatWeb.FlexBar.Helpers

  import OneChat.ServiceHelpers, only: [safe_to_string: 1]

  alias InfinityOne.{Accounts, TabBar.Tab}
  alias OneChatWeb.Client
  alias OneChatWeb.AdminView

  alias InfinityOne.{TabBar, Hooks, OnePubSub}
  alias OneAdminWeb.FlexBarView
  alias OneChatWeb.RebelChannel.Client, as: RebelClient

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
        prefix: "user",
        changeset: {Accounts, :update_user}
      ])
  end

  def args(socket, {user_id, _channel_id, _, sender}, _) do
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

  def notify_cancel(socket, _tab, _sender, client \\ OneChatWeb.Client) do
    client.broadcast_js socket, click_users_link_js()
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
    user = Accounts.get_user(sender["dataset"]["userId"], default_preload: true)

    RebelClient.swal_modal(
      socket,
      ~g(Delete User!),
      gettext("Are you sure you want to delete user %{name}. This cannot be undone.",
        name: user.username),
      "warning",
      ~g(Delete user!),
      confirm: fn _ ->
        case OneChat.Accounts.delete_user(user) do
          {:ok, _} ->
            RebelClient.swal(socket, ~g(Success!), gettext("User %{name} removed.",
              name: user.username), "success")
            async_js(socket, ~s/$('a.admin-link[data-id="admin_users"]').click()/)
          {:error, changeset} ->
            message = OneChatWeb.SharedView.format_errors(changeset) |> String.replace("'", "")
            body = gettext("Could not remove %{name}. ", name: user.username) <> message
            RebelClient.swal(socket, ~g(Error!), body, "error")
        end
      end
    )
    socket
  end

  def notify_update_success(socket, tab, sender, _opts, client \\ OneChatWeb.Client)

  def notify_update_success(socket, %{id: "admin_user_info"}, _sender, %{resource_params: _params} = opts, client) do
    OnePubSub.broadcast "phone_number", "admin", opts
    client.async_js socket, click_users_link_js()
    socket
  end
  def notify_update_success(socket, %{id: "admin_user_info"}, _sender, _opts, client) do
    client.async_js socket, click_users_link_js()
    socket
  end

  def notify_update_success(socket, _tab, _sender, _opts, _) do
    socket
  end

  defp click_users_link_js, do: """
    var link = $('.flex-nav li.active a.admin-link[data-id="admin_users"]');
    if (link) {
      link.click();
    }
    """

  # defp set_active_js(sender), do: """
  #  $('.flex-tab-main-content tr').removeClass('active');
  #  $('#{this(sender)}').addClass('active');
  #   """ |> String.replace("\n", "")

end
