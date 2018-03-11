defmodule OneAdmin.AdminService do
  use OneChat.Shared, :service
  use OneLogger

  import OneAdminWeb.View.Utils, warn: false

  alias OneChat.{Channel, UserService}
  alias OneChatWeb.FlexBarView
  alias OneAdminWeb.{AdminView, AdminChannel}
  alias OneChat.Settings, as: ChatSettings
  alias ChatSettings.{FileUpload, Layout}
  alias ChatSettings.ChatGeneral
  alias InfinityOne.Settings.{General, Accounts}
  alias InfinityOne.{Permissions, Hooks}
  alias InfinityOne.Accounts.{User, UserRole, Role}
  alias OneWebrtc.Settings.Webrtc
  alias OneChatWeb.AdminView, as: ChatAdminView
  alias OneAdminWeb.FlexBarView
  alias OneChatWeb.RebelChannel.Client

  def handle_in("save:accounts", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("accounts")

    resp =
      Accounts.get
      |> Accounts.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"Accounts settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating accounts: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:general", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("general")

    resp =
      General.get
      |> General.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"General settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating general: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:chat_general", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("chat_general")
      |> do_slash_commands_params("chat_slash_commands")
      |> do_slash_commands_params("rooms_slash_commands")

    resp =
      ChatGeneral.get
      |> ChatGeneral.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"General settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating general: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:message", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("message")

    resp =
      ChatSettings.Message.get
      |> ChatSettings.Message.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"Message settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating Message settings: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:layout", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("layout")

    resp =
      Layout.get
      |> Layout.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"Layout settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating Layout settings: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:file_upload", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("file_upload")

    resp =
      FileUpload.get
      |> FileUpload.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"FileUpload settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating FileUpload settings: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:webrtc", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("webrtc")

    resp =
      Webrtc.get
      |> Webrtc.update(params)
      |> case do
        {:ok, _} ->
          {:ok, %{success: ~g"WebRTC settings updated successfully"}}
        {:error, cs} ->
          Logger.error "problem updating WebRTC settings: #{inspect cs}"
          {:ok, %{error: ~g"There a problem updating your settings."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("save:user", params, socket) do
    params =
      params
      |> Helpers.normalize_form_params

    if id = params["id"] do
      user = Helpers.get_user id
      changeset = User.changeset user, params["user"]
      case Repo.update changeset do
        {:ok, _user} ->
          {:reply, {:ok, %{success: ~g(User updated successfully)}}, socket}
        {:error, changeset} ->
          Logger.error "errors: #{inspect changeset.errors}"
          errors = Helpers.format_javascript_errors changeset.errors
          {:reply, {:error, %{error: ~g(Please fix the following errors), errors: errors}}, socket}
      end
    else
    end
  end

  def handle_in(ev = "flex:user-info", %{"name" => name} = params, socket) do
    debug ev, params
    assigns = socket.assigns
    current_user = Helpers.get_user!(assigns.user_id)
    user = Helpers.get_user_by_name(name, preload: [:roles, :account, user_roles: :role])
    user = struct(user, status: OneChat.PresenceAgent.get(user.id))
    html =
      "user_card.html"
      |> FlexBarView.render(user: user, current_user: current_user,
        channel_id: nil, user_info: %{admin: true})
      |> safe_to_string

    {:reply, {:ok, %{html: html, title: "User Info"}}, socket}
  end

  def handle_in(ev = "flex:Invite Users", params, socket) do
    debug ev, params
    assigns = socket.assigns
    current_user = Helpers.get_user!(assigns.user_id)
    html =
      "admin_invite_users.html"
      |> FlexBarView.render(user: current_user, channel_id: nil, user_info: %{admin: true},
         invite_emails: [], error_emails: [], pending_invitations: get_pending_invitations())
      |> safe_to_string

    # {:noreply, socket}
    {:reply, {:ok, %{html: html, title: "Invite Users"}}, socket}
  end

  def handle_in(ev = "flex:send-invitation-email", %{"emails" => emails} = params, socket) do
    debug ev, params
    assigns = socket.assigns
    current_user = Helpers.get_user!(assigns.user_id)
    emails = emails |> String.trim |> String.replace("\n", " ") |> String.split(" ", trim: true)
    case send_invitation_emails(current_user, emails) do
      {:ok, emails} ->
        html =
          "admin_invite_users.html"
          |> FlexBarView.render(user: current_user, channel_id: nil, user_info: %{admin: true},
             invite_emails: emails, error_emails: [], pending_invitations: get_pending_invitations())
          |> safe_to_string
        {:reply, {:ok, %{html: html, title: "Invite Users", success: ~g(Invitations sent successfully.)}}, socket}
      %{errors: errors, ok: emails} ->
        html =
          "admin_invite_users.html"
          |> FlexBarView.render(user: current_user, channel_id: nil, user_info: %{admin: true},
             invite_emails: emails, error_emails: errors, pending_invitations: get_pending_invitations())
          |> safe_to_string
        {:reply, {:ok, %{html: html, title: "Invite Users", warning: ~g(Some of the Invitations were not send.)}}, socket}

      {:error, error} ->
        {:reply, {:error, %{error: error}}, socket}
    end
  end

  def handle_in(ev = "flex:room-info", %{"name" => name} = params, socket) do
    debug ev, params
    assigns = socket.assigns
    current_user = Helpers.get_user!(assigns.user_id)
    channel = Channel.get_by!(name: name)
    html =
      "room_info.html"
      |> AdminView.render(channel: channel, current_user: current_user,
        can_edit: true, editing: nil)
      |> safe_to_string

    {:reply, {:ok, %{html: html, title: "User Info"}}, socket}
  end

  def handle_in("flex:action:" <> action, %{"username" => username} = params, socket) do
    resp =
      case Helpers.get_user_by_name(username, preload: [:roles, :account]) do
        nil ->
          {:error, %{error: ~g(User ) <> username <> ~g( does not exist.)}}
        user ->
          flex_action(action, user, username, params, socket)
      end
    {:reply, resp, socket}
  end
  def handle_in(ev = "channel-settings:edit", %{"channel_id" => channel_id, "field" => field} = params, socket) do
    debug ev, params
    assigns = socket.assigns
    current_user = Helpers.get_user!(assigns.user_id)
    channel = Channel.get!(channel_id)
    html =
      "room_info.html"
      |> AdminView.render(channel: channel, current_user: current_user, can_edit: true, editing: field)
      |> safe_to_string

    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in(ev = "channel-settings:cancel", %{"channel_id" => channel_id} = params, socket) do
    debug ev, params
    current_user = Helpers.get_user!(socket.assigns.user_id)
    channel = Channel.get!(channel_id)
    html =
      "room_info.html"
      |> AdminView.render(channel: channel, current_user: current_user, can_edit: true, editing: nil)
      |> safe_to_string

    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in(ev = "channel-settings:save", %{"channel_id" => channel_id} = params, socket) do
    debug ev, params
    current_user = Helpers.get_user!(socket.assigns.user_id)
    channel = Channel.get!(channel_id)
    html =
      "room_info.html"
      |> AdminView.render(channel: channel, current_user: current_user, can_edit: true, editing: nil)
      |> safe_to_string

    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in(ev = "save:admin-role", params, socket) do
    debug ev, params
    current_user = Helpers.get_user!(socket.assigns.user_id)

    params
    |> Helpers.normalize_form_params
    |> create_or_update_role(current_user, socket)

    {:noreply, socket}
  end

  def handle_in(ev = "permissions:change:" <> change, _params, socket) do
    debug ev, ""
    re = ~r/(?:perm\[)([^\]]+)(?:\]\[)([^\]]+)(?:\])/
    with [_, role, permission_name] <- Regex.run(re, change),
         {false, false} <- {is_nil(permission_name), is_nil(role)},
         permission <- Permissions.get_permission_by_name(permission_name),
         false <- is_nil(permission) do
      Permissions.toggle_role_on_permission(permission, role)
      Client.toastr socket, :success, ~g(Permission changed)
    else
      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr socket, :error, ~g(There was a problem with that action)
    end
    {:noreply, socket}
  end

  def handle_in(ev = "permissions:role:new", _params, socket) do
    debug ev, ""
    # Logger.warn "new role"
    Rebel.Core.async_js socket, ~s/$('.admin-link[data-id="admin_role"]').click();/
    {:noreply, socket}
  end

  def handle_in(ev = "permissions:role:edit", params, socket) do
    debug ev, params
    # Logger.warn "new role params: " <> inspect(params)

    AdminChannel.admin_link("admin_role", socket, Map.put(%{}, "edit-name", params["name"]))
    # {:noreply, socket}
  end

  def handle_in(ev = "permissions:role:delete", params, socket) do
    debug ev, params
    # Logger.warn "new role params: " <> inspect(params)
    role_name = params["name"]
    if role = InfinityOne.Accounts.get_by_role(name: role_name) do
      changeset = InfinityOne.Accounts.change_role(role)

      Client.swal_modal socket, "Delete Role!", "Are you sure?", "warning", "Delete Role!",
        confirm: fn _ ->
          case InfinityOne.Accounts.delete_role changeset do
            {:ok, _} ->
              Client.swal socket, ~g(Role Deleted!), gettext("The %{role} has been successfully deleted", role: role.name), "success"
              Rebel.Core.async_js socket, ~s/$('.admin-link[data-id="admin_permissions"]').click();/
          end
        end
    end
    {:noreply, socket}
  end

  def create_or_update_role(%{"role" => %{"id" => id}} = params, _current_user, socket) do
    debug "create_or_update_role", params

    role = InfinityOne.Accounts.get_role!(id)

    case InfinityOne.Accounts.update_role role, params["role"] do
      {:ok, role} ->
        Client.toastr socket, :success, ~s(Role updated successfully)
        AdminChannel.admin_link("admin_role", socket, Map.put(%{}, "edit-name", role.name))
      {:error, changeset} ->
        Logger.warn "errors: " <> inspect(changeset.errors)
        Client.toastr socket, :error, ~s(Problem creating Role)
    end
  end

  def create_or_update_role(params, _current_user, socket) do
    debug "create_or_update_role", params
    case InfinityOne.Accounts.create_role params["role"] do
      {:ok, role} ->
        Client.toastr socket, :success, ~s(Role created successfully)
        AdminChannel.admin_link("admin_role", socket, Map.put(%{}, "edit-name", role.name))
      {:error, _} ->
        Client.toastr socket, :error, ~s(Problem creating Role)
    end
  end


  # def handle_in(ev = "flex:row-info", params, socket) do
  #   debug ev, params
  #   {:noreply, socket}
  # end

  # defp flex_action("edit-user", user, _username, _params, socket) do
  #   current_user = Helpers.get_user socket.assigns.user_id
  #   html =
  #     "admin_edit_user.html"
  #     |> AdminView.render(user: user, current_user: current_user)
  #     |> safe_to_string
  #   {:ok, %{html: html, title: "Edit User"}}
  # end

  defp flex_action("delete" = ev, user, _username, _params, socket) do
    debug ev, user
    current_user = Helpers.get_user socket.assigns.user_id
    if Permissions.has_permission?(current_user, "delete-user") do
      case UserService.delete_user user do
        {:ok, _} ->
          {:ok, %{success: "User deleted successfully."}}
        {:erorr, _error} ->
          {:error, %{error: "There was a problem deleting the User"}}
      end
    else
      {:error, %{error: ~g(Unauthorized action)}}
    end
  end

  defp flex_action(action, user, _username, _params, _socket) when action in ~w(make-admin remove-admin) do
    debug "flex_action", action
    [role1, role2, success, error] =
      if action == "make-admin" do
        ["user", "admin", ~g(User is now an admin), ~g(Problem  making the an admin)]
      else
        ["admin", "user", ~g(User is no longer an admin), ~g(Problem encountered. User is still an admin)]
      end

    (from r in UserRole, where: r.user_id == ^(user.id) and r.role == ^role2 and is_nil(r.scope))
    |> Repo.one
    |> case do
      nil ->
        (from r in UserRole, where: r.user_id == ^(user.id) and r.role == ^role1 and is_nil(r.scope))
        |> Repo.one
        |> Repo.delete

        %UserRole{}
        |> UserRole.changeset(%{user_id: user.id, role: role2, scope: nil})
        |> Repo.insert
        |> case do
          {:ok, _} ->
            html =
              user.id
              |> Helpers.get_user
              |> ChatAdminView.render_user_action_button("admin")
              |> safe_to_string
            {:ok, %{success: success, code_update: %{selector: "button." <> action, action: "replaceWith", html: html}}}
          {:error, _} ->
            {:error, %{error: error}}
        end
      _ ->
        {:error, %{error: ~g(User already has that role)}}
    end
  end

  defp flex_action(action, user, _username, _params, _socket) when action in ~w(activate deactivate) do
    debug "flex_action", action
    [active, success, error, svc] =
      if action == "activate" do
        [true, ~g(User has been activated), ~g(Problem activating User), &UserService.activate_user/1]
      else
        [false, ~g(User has been deactivated), ~g(Problem encountered. User is still activated), &UserService.deactivate_user/1]
      end

    user
    |> svc.()
    |> User.changeset(%{active: active})
    |> Repo.update
    |> case do
      {:ok, user} ->
        html =
          user
          |> ChatAdminView.render_user_action_button("activate")
          |> safe_to_string
        {:ok, %{success: success, code_update: %{selector: "button." <> action, action: "replaceWith", html: html}}}
      {:error, _} ->
        {:error, %{error: error}}
    end
  end

  def do_slash_commands_params(params, which) do
    debug "do_slash_commands_params", params
    slash_commands =
      params
      |> Map.get(which, [])
      |> Enum.reduce([], fn
        {opt, "on"}, acc -> [opt|acc]
        _, acc -> acc
      end)
      |> Enum.join("\n")

    put_in(params, [which], slash_commands)
  end

  def render(user, link, templ) do
    Helpers.render(AdminView, templ, get_args(link, user))
  end

  def render_info(_user) do
    render(AdminView, "info", "info.html")
  end

  def get_args("permissions", user) do
    roles = Repo.all Role
    permissions = Permissions.all

    [user: user, roles: roles, permissions: permissions]
  end

  def get_args("general", user) do
    # view_a = String.to_atom view
    cs = InfinityOne.Settings.General.changeset(InfinityOne.Settings.General.get())
    [user: user, changeset: cs]
  end
  def get_args("webrtc", user) do
    # view_a = String.to_atom view
    cs = OneWebrtc.Settings.Webrtc.changeset(OneWebrtc.Settings.Webrtc.get())
    [user: user, changeset: cs]
  end
  def get_args(view, user) when view in ~w(chat_general message layout file_upload) do
    # view_a = String.to_atom view
    mod = Module.concat OneChat.Settings, InfinityOne.Utils.to_camel_case(view)
    cs = mod.changeset(mod.get())
    [user: user, changeset: cs]
  end
  def get_args("users", user) do
    preload = Hooks.user_preload []
    user = Repo.preload user, preload

    users =
      (from u in User, order_by: [asc: u.username], preload: ^preload)
      |> Repo.all
      |> Hooks.all_users_post_filter

    [user: user, users: users]
  end
  # def get_args("rooms", user) do
  #   # view_a = String.to_atom view
  #   # mod = Module.concat Config, String.capitalize(view)
  #   rooms = Repo.all(from c in ChannelSchema, order_by: [asc: c.name],
  #     preload: [:subscriptions, :messages])
  #   [user: user, rooms: rooms]
  # end
  # # defp get_args("message", user) do
  # #   cs =
  # #     Config
  # #     |> Repo.one
  # #     |> Map.get(:message)
  # #     |> Config.Message.changeset(%{})
  # #   [user: user, changeset: cs]
  # # end
  # def get_args("info", user) do
  #   total = UserService.total_users_count()
  #   online = UserService.online_users_count()

  #   usage = [
  #     %{title: ~g"Total Users", value: total},
  #     %{title: ~g"Online Users", value: online},
  #     %{title: ~g"Offline Users", value: total - online},
  #     %{title: ~g"Total Rooms", value: Channel.total_rooms() |> Repo.one},
  #     %{title: ~g"Total Channels", value: Channel.total_channels() |> Repo.one},
  #     %{title: ~g"Total Private Groups", value: Channel.total_private() |> Repo.one},
  #     %{title: ~g"Total Direct Message Rooms", value: Channel.total_direct() |> Repo.one},
  #     %{title: ~g"Total Messages", value: Message.total_count() |> Repo.one},
  #     %{title: ~g"Total Messages in Channels", value: Message.total_channels() |> Repo.one},
  #     %{title: ~g"Total in Private Groups", value: Message.total_private() |> Repo.one},
  #     %{title: ~g"Total in Direct Messages", value: Message.total_direct() |> Repo.one},
  #   ]

  #   [user: user, info: info]
  # end

  def send_invitation_emails(_current_user, emails) do
    Enum.reject(emails, fn email ->
      email
      |> String.trim
      |> String.match?(~r/^[_a-z0-9-]+(.[a-z0-9-]+)@[a-z0-9-]+(.[a-z0-9-]+)*(.[a-z]{2,4})$/)
    end)
    |> case do
      [] ->
        Enum.map(emails, fn email ->
          OneChat.InvitationService.create_and_send(email)
        end)
        |> Enum.split_with(fn
          {:ok, _} -> false
          _ -> true
        end)
        |> case do
          {[], list} ->
            {:ok, get_emails(list)}
          {errors, oks} ->
            %{errors: get_emails(errors) |> Enum.join("\n"), ok: get_emails(oks)}
        end

      errors ->
        {:error, "The following emails are not in the correct format: " <> Enum.join(errors, " ")}
    end
  end

  defp get_emails(list) do
    Enum.map list, fn
      {:ok, inv} -> inv.email
      {:error, cs} -> cs.changes[:email]
    end
  end

  def get_pending_invitations do
    InfinityOne.Coherence.Invitation
    |> Repo.all
  end

end
