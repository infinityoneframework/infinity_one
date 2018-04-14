defmodule OneAdminWeb.AdminChannel do

  import Rebel.Query, warn: false
  import Rebel.Core, warn: false
  import InfinityOneWeb.Gettext
  import Phoenix.View, only: [render_to_string: 3]

  alias OneAdminWeb.AdminView
  alias OneChatWeb.RebelChannel.{SideNav}
  alias OneChatWeb.{RebelChannel.Client}
  alias Rebel.SweetAlert
  alias InfinityOne.Accounts
  alias InfinityOneWeb.Query
  alias OneChat.Channel


  require Logger

  def click_admin(socket, sender) do
    # Logger.debug inspect(sender)
    SideNav.open socket
    admin_link "admin_info", socket, sender
  end

  def admin_link(socket, sender) do
    # Logger.debug inspect(sender)
    admin_link sender["dataset"]["id"], socket, sender
  end

  def admin_link(id, socket, sender) do
    page = OneAdmin.get_page id
    {:noreply, apply(page.module, :open, [socket, sender, page])}
  end

  def admin_flex(socket, _sender) do
    # Logger.debug "sender: #{inspect sender}"
    {:noreply, socket}
  end

  def admin_click_user_role_member(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)

    select_member sender["dataset"]["id"], sender, socket
  end

  def admin_user_roles(socket, %{"event" => %{"key" => key}})
    when key in ~w(ArrowDown ArrowUp ArrowLeft ArrowRight) do

    socket
  end

  def admin_user_roles(socket, %{"event" => %{"key" => key}} = sender)
    when key in ~w(Tab Enter) do

    socket
    |> get_selected_user_item()
    |> select_member(sender, socket)
    |> set_add_button_focus()
  end

  def admin_user_roles(socket, sender) do
    socket
    |> get_search_control()
    |> render_members_list(socket, sender)
  end

  defp render_members_list("", socket, _sender) do
    {:noreply, clear_selected_users(socket)}
  end

  defp render_members_list(pattern, socket, sender) do
    # Logger.warn ""
    role_id = sender["dataset"]["id"] |> String.to_integer
    user = Accounts.get_user socket.assigns.user_id

    scope = get_scope(socket) |> IO.inspect(label: "scope")

    users =
      ("%" <> pattern <> "%")
      |> InfinityOne.Accounts.list_users_without_role_by_pattern(role_id, count: 8, scope: scope)
      |> Enum.map(& Map.put(&1, :status, OneChat.PresenceAgent.get(&1.id)))

    html = render_to_string OneChatWeb.AdminView, "permissions_users_autocomplete.html",
      [user: user, users: users]

    socket
    |> Query.delete(class: "hidden", on:  ".-autocomplete-container.users")
    |> Query.update(:replaceWith, set: html, on: ".-autocomplete-container.users")
    |> set_search_control_focus()

    {:noreply, socket}
  end

  defp select_member(nil, _sender, socket) do
    {:noreply, socket}
  end

  defp select_member(username, _sender, socket) do
    # Logger.warn "selected username #{inspect username}"
    case Accounts.get_by_user username: username do
      nil ->
        nil
      _user ->
        socket
        |> set_search_control(username)
        |> set_add_button()
        |> clear_selected_users()
        |> set_add_button_focus()
    end

    {:noreply, socket}
  end

  def admin_add_user_role(socket, _sender) do
    # Logger.warn "sender: " <> inspect(sender)

    scope = get_scope(socket)

    with username <- get_search_control(socket),
         {:username, false} <- {:username, is_nil(username)},
         user <- Accounts.get_by_username(username),
         {:user, false} <- {:user, is_nil(user)},
         role_name <- get_role_name(socket),
         {:role, false} <- {:role, is_nil(role_name)},
         {:ok, _} <- Accounts.add_role_to_user(user, role_name, scope) do

      socket
      |> Client.toastr(:success, ~g(Added role to user.))
      |> clear_selected_users()
      |> set_search_control()
      |> set_add_button(:disabled)
      |> update_member_list(role_name, scope)
      |> set_search_control_focus()
    else
      {:username, true} -> {:error, ~g(System error. Could not find the username.)}
      {:user, true} -> {:error, ~g(Invalid username.)}
      {:role, true} -> {:error, ~g(System error. Could not find the role name.)}
      {:error, changeset} ->
        Logger.warn "errors: " <> inspect(changeset.errors)
        {:error, ~g(Failed to add the role.)}

      other ->
        Logger.warn "Something went wrong. Result: " <> inspect(other)
        {:error, ~g(System error. Something went wrong.)}
    end
    |> case do
      {:error, message} ->
        Client.toastr socket, :error, message
      _ -> :ok
    end

    {:noreply, socket}
  end

  defp update_member_list(socket, %{} = role, scope) do
    # Logger.warn ""
    html = render_to_string OneChatWeb.AdminView,
      "permissions_user_roles.html", users: role.users, scope: scope

    Query.update socket, :html, set: html, on: ".list-user-roles"
  end

  defp update_member_list(socket, role_name, scope) do
    # Logger.warn ""
    role = get_role_by_name socket, role_name, scope
    update_member_list socket, role, scope
  end

  def admin_user_role_remove(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)

    scope = get_scope(socket)
    scope_params = fn list ->
      if scope, do: [{:scope, scope} | list], else: list
    end

    with role_name <- get_role_name(socket),
         {:role_name, false} <- {:role_name, is_nil(role_name)},
         role <- get_role_by_name(socket, role_name, scope),
         {:role, false} <- {:role, is_nil(role)},
         username <- sender["dataset"]["username"],
         {:username, false} <- {:username, is_nil(username)},
         user <- Accounts.get_by_username(username),
         true <- check_admin_role(role, user, socket.assigns.user_id, scope),
         {:user, false} <- {:user, is_nil(user)},
         user_role <- Accounts.get_by_user_role(scope_params.(user_id: user.id, role_id: role.id)),
         {:ok, _} <- Accounts.delete_user_role(user_role) do

      socket
      |> Client.toastr(:success, ~g(User's role removed.))
      |> update_member_list(role_name, scope)
    else
      {:not_allowed, message} ->
        Client.toastr socket, :error, message

      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr socket, :error, ~g(Opps, something went wrong)
    end

    {:noreply, socket}
  end

  defp check_admin_role(%{name: "admin"} = role, user, user_id, _) do
    cond do
      Accounts.count_user_roles(role) == 1 ->
        {:not_allowed, ~g(Can't delete the last admin account)}
      user.id == user_id ->
        {:not_allowed, ~g(Can't delete our own admin role. Please have another administrator do it.)}
      true ->
        true
    end
  end

  defp check_admin_role(%{name: "owner"} = role, _user, _user_id, scope) do
    cond do
      Accounts.count_user_roles(role, scope) == 1 ->
        {:not_allowed, ~g(Can't delete the last room owner. Please add another owner first.)}
      true ->
        true
    end
  end

  defp check_admin_role(_role, _user, _user_id, _), do: true


  def get_role_by_name(socket, role_name, scope \\ :none) do
    scope =
      if scope == :none do
        get_scope(socket)
      else
        scope
      end

    if scope do
      value = get_search_room_control(socket)
      if channel = Channel.get_by name: value do
        Accounts.get_role_by_name_with_users(role_name, channel.id)
      else
        nil
      end
    else
      Accounts.get_role_by_name_with_users(role_name)
    end
  end

  # defp get_user!(%{assigns: %{user_id: user_id}}) do
  #   Accounts.get_user! user_id, preload: [:account, :roles]
  # end

  def render_to_string(templ, bindings \\ []) do
    Phoenix.View.render_to_string AdminView, templ, bindings
  end

  def admin_restart_server(socket, _sender) do
    SweetAlert.swal_modal socket, ~g(Are you sure?),
      ~g(This will disrupt service for all active users), "warning",
      [
        showCancelButton: true, closeOnConfirm: false, closeOnCancel: true,
        confirmButtonColor: "#DD6B55", confirmButtonText: ~g(Yes, restart it)
      ],
      confirm: fn _ ->
        {title, message, status} =
          case Application.get_env(:infinity_one, :restart_command) do
            [command | args] ->
              if System.find_executable(command) do
                try do
                  case System.cmd command, args do
                    {_, 0} ->
                      {~g"Restarting!", ~g"The server is being restarted!", "success"}
                    {error, code} ->
                      {gettext("Error %{code}", code: code), error , "error"}
                  end
                rescue
                  _ ->
                   {~g(Sorry), ~g(Something went wong), "error"}
                end
              else
                {~g(Sorry), ~g(The configured restart command cannot be found), "error"}
              end
            nil ->
              {~g(Sorry), ~g(The restart command is not configured!), "error"}

          end
        SweetAlert.swal(socket, title, message, status, timer: 5000, showConfirmButton: false)
      end
    socket
  end

  def admin_click_scoped_room(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)

    sender["dataset"]["id"]
    |> select_room(socket)
    |> clear_selected_rooms
  end

  def admin_autocomplete_mouseenter(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)
    sender["text"]
    |> String.trim
    |> select_room(socket, focus: false)
  end

  def admin_user_role_search_channel(socket, %{"event" => %{"key" => key}})
    when key in ~w(ArrowDown ArrowUp) do

    selected = get_selected_room_item(socket)

    selected
    |> String.trim
    |> select_room(socket, focus: false)
  end

  def admin_user_role_search_channel(socket, %{"event" => %{"key" => key}})
    when key in ~w(ArrowLeft ArrowRight) do

    socket
  end

  def admin_user_role_search_channel(socket, %{"event" => %{"key" => key}})
    when key in ~w(Tab Enter) do
    # Logger.warn "sender: " <> inspect(sender)

    socket
    |> get_selected_room_item()
    |> select_room(socket)
    |> clear_selected_rooms()
  end

  def admin_user_role_search_channel(socket, _sender) do
    # Logger.warn "sender: " <> inspect(sender)
    socket
    |> get_search_room_control()
    |> render_rooms_list(socket)
  end

  def render_rooms_list("", socket) do
    clear_selected_rooms(socket)
  end

  def render_rooms_list(pattern, socket) do
    # Logger.warn ""
    rooms =
      ("%" <> pattern <> "%")
      |> Channel.get_all_channels_by_pattern(8)

    html = render_to_string OneChatWeb.AdminView, "permissions_rooms_autocomplete.html",
      [rooms: rooms]

    socket
    |> Query.update(:html, set: html, on: ".-autocomplete-container.rooms")
    |> show_selected_rooms()
  end

  def select_room(room, socket, opts \\ []) do
    # Logger.warn "room: " <> inspect(room)
    set_search_room_control socket, room

    if channel = Channel.get_by name: room do
      role =
        socket
        |> get_role_name()
        |> Accounts.get_role_by_name_with_users(channel.id)

      html = render_to_string OneChatWeb.AdminView, "permissions_user_roles_container.html",
        item: role, scope: channel.id

      socket
      |> Query.update(:html, set: html, on: "#user-roles-container")
      |> set_search_control_focus(opts)
    else
      Logger.warn "did not found room #{room}"
      socket
    end
  end

  def get_scope(socket) do
    case exec_js!(socket, ~s/$('.user-roles-container').attr('data-scope')/) do
      "" -> nil
      other -> other
    end
  end

  def admin_reset_setting_click(socket, sender) do
    setting_name = sender["dataset"]["setting"]
    [mod, field] = String.split(setting_name, "__", trim: true)
    module = OneSettings.module_map(mod)
    field = String.to_existing_atom(field)
    schema = apply(module, :schema, [])
    default = Map.get(schema.__struct__, field)

    control_type = Rebel.Core.exec_js!(socket,
      ~s/let e=$('[name="#{mod}[#{field}]"]'); e.attr('type') + ' ' + e.get(0).tagName/)

    selector = "#" <> String.replace(setting_name, "__", "_")

    case String.split(control_type) do
      [_, "TEXTAREA"] ->
        Rebel.Query.update(socket, :val, set: default, on: selector)
      ["radio", _] ->
        selector = selector <> "_"
        which = if default in [true, "true"], do: "1", else: "0"
        Rebel.Query.update(socket, prop: "checked", set: true, on: selector <> which)
      [_, "INPUT"] ->
        Rebel.Query.update(socket, :val, set: default, on: selector)
      [_, "SELECT"] ->
        Rebel.Query.update(socket, :val, set: default, on: selector)
      other ->
        raise "invalid control type: #{inspect other}"
    end

    socket
    |> async_js(~s/OneChat.admin.enable_save_button()/)
    |> async_js(~s/$('[data-setting="#{setting_name}"]').closest('.input-line').addClass('setting-changed')/)
    |> async_js(~s/$('[data-setting="#{setting_name}"]').remove()/)
  end

  defp clear_selected_users(socket) do
    async_js socket, ~s/$('.-autocomplete-container.users').addClass('hidden')/
  end

  defp clear_selected_rooms(socket) do
    async_js socket, ~s/$('.-autocomplete-container.rooms').addClass('hidden')/
  end

  defp get_selected_user_item(socket) do
    exec_js!(socket, "$('.-autocomplete-container.users li.-autocomplete-item.selected').attr('data-id');")
  end

  defp get_selected_room_item(socket) do
    exec_js!(socket, "$('.-autocomplete-container.rooms li.-autocomplete-item.selected').attr('data-id');")
  end

  defp get_search_control(socket) do
    exec_js!(socket, ~s/$('#user-roles-search').val()/)
  end

  defp set_search_control(socket, value \\ "") do
    async_js(socket, ~s/$('#user-roles-search').val('#{value}')/)
  end

  defp set_search_control_focus(socket, opts \\ []) do
    if Keyword.get(opts, :focus, true) do
      async_js(socket, ~s/$('#user-roles-search').focus()/)
    else
      socket
    end
  end

  defp set_add_button_focus({:noreply, socket}) do
    {:noreply, set_add_button_focus(socket)}
  end

  defp set_add_button_focus(socket) do
    async_js(socket, ~s/$('.user-roles button.add').focus()/)
  end

  defp set_add_button(socket, opt \\ nil)

  defp set_add_button(socket, :disabled) do
    async_js(socket, ~s/$('.user-roles button.add').attr('disabled', true)/)
  end

  defp set_add_button(socket, _) do
    async_js(socket, ~s/$('.user-roles button.add').removeAttr('disabled')/)
  end

  defp get_role_name(socket) do
    exec_js!(socket, ~s/$('#user-roles-container').attr('data-role')/)
  end

  defp get_search_room_control(socket) do
    exec_js! socket, ~s/$('#search-room').val()/
  end

  defp set_search_room_control(socket, value) do
    async_js socket, ~s/$('#search-room').val('#{value}')/
  end

  defp show_selected_rooms(socket) do
    async_js socket, ~s/$('.-autocomplete-container.rooms').removeClass('hidden')/
  end

  def admin_new_pattern(socket, _sender) do
    last_id_string = Rebel.Core.exec_js!(socket, ~s/$('.input-line.message-pattern').last().attr('data-id')/)
    index =
      case is_binary(last_id_string) && Integer.parse(last_id_string) do
        {int, ""} -> int + 1
        _ -> 0
      end

    html = Phoenix.View.render_to_string(OneChatWeb.AdminView, "replacement_pattern.html", bindings: [hidden: true, index: index])

    socket
    |> Rebel.Query.insert(html, before: ~s/a.new-message-pattern/)
    |> async_js(~s/$('a.new-message-pattern').prev().show('slow')/)
  end

end
