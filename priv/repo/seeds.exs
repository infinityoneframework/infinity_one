alias UcxUcc.Repo
alias UcxUcc.{Accounts, Permissions}
alias Accounts.{User, Role, UserRole}
alias Permissions.{Permission, PermissionRole}

Repo.delete_all PermissionRole
Repo.delete_all UserRole
Repo.delete_all Permission
Repo.delete_all Role
Repo.delete_all User

default_permissions = [
    %{name: "access-permissions",            roles: ["admin"] },
    %{name: "add-oauth-service",             roles: ["admin"] },
    %{name: "add-user-to-joined-room",       roles: ["admin", "owner", "moderator"] },
    %{name: "add-user-to-any-c-room",        roles: ["admin"] },
    %{name: "add-user-to-any-p-room",        roles: [] },
    %{name: "archive-room",                  roles: ["admin", "owner"] },
    %{name: "assign-admin-role",             roles: ["admin"] },
    %{name: "ban-user",                      roles: ["admin", "owner", "moderator"] },
    %{name: "bulk-create-c",                 roles: ["admin"] },
    %{name: "bulk-register-user",            roles: ["admin"] },
    %{name: "create-c",                      roles: ["admin", "user", "bot"] },
    %{name: "create-d",                      roles: ["admin", "user", "bot"] },
    %{name: "create-p",                      roles: ["admin", "user", "bot"] },
    %{name: "create-user",                   roles: ["admin"] },
    %{name: "clean-channel-history",         roles: ["admin"] },
    %{name: "delete-c",                      roles: ["admin"] },
    %{name: "delete-d",                      roles: ["admin"] },
    %{name: "delete-message",                roles: ["admin", "owner", "moderator"] },
    %{name: "delete-p",                      roles: ["admin"] },
    %{name: "delete-user",                   roles: ["admin"] },
    %{name: "edit-message",                  roles: ["admin", "owner", "moderator"] },
    %{name: "edit-other-user-active-status", roles: ["admin"] },
    %{name: "edit-other-user-info",          roles: ["admin"] },
    %{name: "edit-other-user-password",      roles: ["admin"] },
    %{name: "edit-privileged-setting",       roles: ["admin"] },
    %{name: "edit-room",                     roles: ["admin", "owner", "moderator"] },
    %{name: "manage-assets",                 roles: ["admin"] },
    %{name: "manage-emoji",                  roles: ["admin"] },
    %{name: "manage-integrations",           roles: ["admin"] },
    %{name: "manage-own-integrations",       roles: ["admin", "bot"] },
    %{name: "manage-oauth-apps",             roles: ["admin"] },
    %{name: "mention-all",                   roles: ["admin", "owner", "moderator", "user"] },
    %{name: "mute-user",                     roles: ["admin", "owner", "moderator"] },
    %{name: "remove-user",                   roles: ["admin", "owner", "moderator"] },
    %{name: "run-import",                    roles: ["admin"] },
    %{name: "run-migration",                 roles: ["admin"] },
    %{name: "set-moderator",                 roles: ["admin", "owner"] },
    %{name: "set-owner",                     roles: ["admin", "owner"] },
    %{name: "unarchive-room",                roles: ["admin"] },
    %{name: "view-c-room",                   roles: ["admin", "user", "bot"] },
    %{name: "view-d-room",                   roles: ["admin", "user", "bot"] },
    %{name: "view-full-other-user-info",     roles: ["admin"] },
    %{name: "view-history",                  roles: ["admin", "user"] },
    %{name: "view-joined-room",              roles: ["guest", "bot"] },
    %{name: "view-join-code",                roles: ["admin"] },
    %{name: "view-logs",                     roles: ["admin"] },
    %{name: "view-other-user-channels",      roles: ["admin"] },
    %{name: "view-p-room",                   roles: ["admin", "user"] },
    %{name: "view-privileged-setting",       roles: ["admin"] },
    %{name: "view-room-administration",      roles: ["admin"] },
    %{name: "view-message-administration",   roles: ["admin"] },
    %{name: "view-statistics",               roles: ["admin"] },
    %{name: "view-user-administration",      roles: ["admin"] },
    %{name: "preview-c-room",                roles: ["admin", "user"] }
  ]

roles =
  [admin: :global, moderator: :rooms, owner: :rooms, user: :global, bot: :global, guest: :global]
  |> Enum.map(fn {role, scope} ->
    %{name: to_string(role), scope: to_string(scope)}
    |> Accounts.create_role()
    |> elem(1)
  end)
  |> Enum.map(fn %{name: name, id: id} -> {to_string(name), id} end)
  |> Enum.into(%{})

create_username = fn name ->
  name
  |> String.downcase
  |> String.split(" ", trim: true)
  |> Enum.join(".")
end

create_user = fn name, email, password, admin ->
  username = create_username.(name)
  params = %{
    username: username, name: name, email: email,
    password: password, password_confirmation: password
  }
  params = if admin == :bot, do: Map.put(params, :avatar_url, "/images/hubot.png"), else: params
  user =
    %User{}
    |> User.changeset(params)
    |> Repo.insert!

  role_id = case admin do
    true -> roles["admin"]
    false -> roles["user"]
    :bot -> roles["bot"]
  end

  Accounts.create_user_role(%{user_id: user.id, role_id: role_id})

  user
end

# build the permissions
roles_list = roles
default_permissions
|> Enum.each(fn %{name: name, roles: roles} ->
  {:ok, permission} = Permissions.create_permission(%{name: name})
  roles
  |> Enum.each(fn role_name ->
    Permissions.create_permission_role(%{permission_id: permission.id, role_id: roles_list[role_name]})
  end)
end)

# build the users
_u0 = create_user.("Bot", "bot@example.com", "test", :bot)
_u1 = create_user.("Admin", "admin@spallen.com", "test", true)
_u2 = create_user.("Steve Pallen", "steve.pallen@spallen.com", "test", true)
