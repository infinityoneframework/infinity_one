alias UcxUcc.Repo
alias UcxUcc.{Accounts, Permissions}
alias Accounts.{User, Role, UserRole, Account, PhoneNumber, PhoneNumberLabel}
alias Permissions.{Permission, PermissionRole}
alias UccChat.{Subscription, Message, Channel}

Message.delete_all
Subscription.delete_all
Channel.delete_all

Repo.delete_all PhoneNumberLabel
Repo.delete_all PhoneNumber
Repo.delete_all PermissionRole
Repo.delete_all UserRole
Repo.delete_all Permission
Repo.delete_all Role
Repo.delete_all Account
Repo.delete_all User

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
  Accounts.get_user user.id, default_preload: true
end

IO.puts "Creating Permissions"
# build the permissions
Repo.delete_all UcxUcc.Permissions.Permission

roles_list = roles

UcxUcc.Permissions.default_permissions()
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

IO.puts "Setting phone number labels"

~w(Work Home Mobile)
|> Enum.map(fn label ->
    Accounts.create_phone_number_label! %{name: label}
end)
