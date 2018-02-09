alias UcxUcc.Repo
alias UcxUcc.{Accounts, Permissions}
alias Accounts.{User, Role, UserRole, Account, PhoneNumber, PhoneNumberLabel}
alias Permissions.{Permission, PermissionRole}
alias UccChat.{Subscription, Message, Channel}
alias UcxPresence.Extension
alias Mscs.Client

Message.delete_all
Subscription.delete_all
Channel.delete_all
Mscs.Apb.delete_all

Repo.delete_all PhoneNumberLabel
Repo.delete_all PhoneNumber
Repo.delete_all PermissionRole
Repo.delete_all UserRole
Repo.delete_all Permission
Repo.delete_all Role
Repo.delete_all Account
Repo.delete_all User

# TODO: Move this to the Permissions module so its all in one place.
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

IO.puts "Creating Roles"

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
  |> hd
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
    |> Repo.preload([:phone_numbers])

  Coherence.Controller.confirm! user

  role_id = case admin do
    true -> roles["admin"]
    false -> roles["user"]
    :bot -> roles["bot"]
  end

  Accounts.create_user_role(%{user_id: user.id, role_id: role_id})
  Accounts.create_account(%{user_id: user.id})
  user
end

IO.puts "Creating Permissions"
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

IO.puts "Creating First Users"
# build the users
random_string = fn len ->
  chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%&'
  for _ch <- 1..len do
    Enum.random chars
  end
  |> to_string
end

_u0 = create_user.("Bot", "bot@example.com", random_string.(32), :bot)

IO.puts "Creating Settings"

UccSettings.init_all()

start_mac = Application.get_env :mscs, :base_mac_address, 0x144ffc0000

IO.puts "Setting mac addresses"

Client.list
|> Enum.with_index
|> Enum.each(fn {user, inx} ->
  mac = start_mac + inx + 1
  Client.update(user, %{mac: mac})
end)


IO.puts "Setting phone numbers"

~w(Work Home Mobile)
|> Enum.map(fn label ->
    Accounts.create_phone_number_label! %{name: label}
end)
