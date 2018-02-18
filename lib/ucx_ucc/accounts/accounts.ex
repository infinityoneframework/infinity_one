defmodule UcxUcc.Accounts do

  import Ecto.{Query, Changeset}, warn: false
  alias UcxUcc.Repo

  # alias UcxUcc.Accounts.User
  alias UcxUcc.Accounts.{Role, UserRole, User, Account}
  alias UcxUcc.Hooks
  require Logger
  # alias UcxUcc.Permissions.{Permission, PermissionRole}

  @default_user_preload [:account, :roles, user_roles: :role]

  def default_user_preloads, do: Hooks.user_preload(@default_user_preload)

  ##################
  # User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users([preload: preload]) do
    Repo.all from u in User, preload: ^preload
  end

  def list_users_by_pattern(user_ids, pattern, count \\ 8) do
    User
    |> where([c], like(c.username, ^pattern) and c.id in ^user_ids)
    |> join(:left, [c], r in assoc(c, :roles))
    |> where([c, r], not(r.name == "bot" and r.scope == "global"))
    |> preload([c, r], [roles: c])
    |> select([c], c)
    |> order_by([c], desc: c.inserted_at)
    |> limit(^count)
    |> Repo.all
  end

  def list_all_users_by_pattern(pattern, {column, exclude}, count) do
    pattern = String.downcase(pattern)
    User
    |> where([c], like(fragment("LOWER(?) or LOWER(?) or LOWER(?)",
      c.username, c.name, c.email), ^pattern) and
      not field(c, ^column) in ^exclude)
    |> join(:left, [c], r in assoc(c, :roles))
    |> where([c, r], not(r.name == "bot" and r.scope == "global"))
    |> preload([c, r], [roles: c])
    |> order_by([c], asc: c.username)
    |> limit(^count)
    |> Repo.all
  end

  def list_all_users_by_pattern(pattern, exclude, count) do
    list_all_users_by_pattern(pattern, {:id, exclude}, count)
  end

  def list_users_without_role_by_pattern(pattern, role_id, opts \\ []) do
    pattern = String.downcase(pattern)
    count = opts[:count] || 8
    scope = opts[:scope]
    User
    |> where([c], like(fragment("LOWER(?) or LOWER(?) or LOWER(?)",
      c.username, c.name, c.email), ^pattern))
    |> do_list_users_without_role_by_pattern_join(role_id, scope)
    |> where([c,r], is_nil(r.id))
    |> where([c], not like(c.username, "bot%"))
    |> select([c], %{id: c.id, username: c.username, email: c.email, name: c.name})
    |> order_by([c], asc: c.username)
    |> limit(^count)
    |> Repo.all
  end

  defp do_list_users_without_role_by_pattern_join(query, role_id, nil) do
    join(query, :left, [c], r in UserRole, r.role_id == ^role_id and r.user_id == c.id)
  end
  defp do_list_users_without_role_by_pattern_join(query, role_id, scope) do
    join(query, :left, [c], r in UserRole, r.role_id == ^role_id and r.user_id == c.id and r.scope == ^scope)
  end

  defp pop_user_preloads(opts) do
    if opts[:default_preload] do
      {default_user_preloads(), Keyword.delete(opts, :default_preload)}
    else
      Keyword.pop(opts, :preload, [])
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(45
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)
  def get_user!(id, opts) do
    {preload, _} = pop_user_preloads(opts)
    Repo.one! from u in User, where: u.id == ^id, preload: ^preload
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user(id, opts) do
    {preload, _} = pop_user_preloads(opts)
    Repo.one from u in User, where: u.id == ^id, preload: ^preload
  end

  def get_by_user(opts) do
    {preload, opts} = pop_user_preloads(opts)
    opts
    |> Enum.reduce(User, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.one
  end

  def list_by_user(opts) do
    {preload, opts} = pop_user_preloads(opts)
    opts
    |> Enum.reduce(User, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.all
  end

  def username_by_user_id(id, opts \\ []) do
    {preload, _} = pop_user_preloads(opts)
    case get_user id, preload: preload do
      nil -> nil
      user -> user.username
    end
  end

  def get_by_username(username, opts \\ []) do
    get_by_user [{:username, username} | opts]
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    {account_key, subs_key} =
      case Map.keys(attrs) do
        [k | _] when is_atom(k) ->
          {:account, :subscriptions}
        _ ->
          {"account", "subscriptions"}
      end
    subs =
      true
      |> UccChat.Channel.list_by_default()
      |> Enum.map(& %{channel_id: &1.id})
    attrs =
      attrs
      |> Map.put(subs_key, subs)
      |> put_account(account_key)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  defp put_account(attrs, key) do
    if attrs[key] do
      attrs
    else
      Map.put attrs, key, %{}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_user!(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update!()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def change_user(%{} = params) do
    User.changeset(%User{}, params)
  end

  def add_role_to_user(user, role, scope \\ nil)
  def add_role_to_user(%User{} = user, %Role{} = role, scope) do
    create_user_role %{user_id: user.id, role_id: role.id, scope: scope}
  end

  def add_role_to_user(%User{} = user, role_name, scope) do
    add_role_to_user user, get_role_by_name(role_name), scope
  end

  ##################
  # Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id), do: Repo.get!(Role, id)

  def get_by_role(opts) do
    if preload = opts[:preload] do
      Role
      |> Repo.get_by(Keyword.delete(opts, :preload))
      |> Repo.preload(preload)
    else
      Repo.get_by Role, opts
    end
  end

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  def delete_role(%Ecto.Changeset{} = changeset) do
    Repo.delete(changeset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{source: %Role{}}

  """
  def change_role(%Role{} = role) do
    Role.changeset(role, %{})
  end

  def change_role do
    change_role %Role{}
  end

  @doc """
  Creates a list of roles.

  ## Examples

      iex> create_roles([admin: :global, owner: :rooms])

  """
  def create_roles(roles) do
    roles
    |> Enum.map(fn {role, scope} ->
      %{name: to_string(role), scope: to_string(scope)}
      |> create_role()
      |> elem(1)
    end)
    |> Enum.map(fn %{name: name, id: id} -> {to_string(name), id} end)
    |> Enum.into(%{})
  end

  @doc """
  Returns a role by role name
  """
  def get_role_by_name(role, opts \\ []) do
    preload = opts[:preload] || []
    Repo.one from r in Role, where: r.name == ^role, preload: ^preload
  end

  def set_users_role(%{} = user, role_name, scope) do
    with role when not is_nil(role) <- get_role_by_name(role_name),
         {:ok, _} <- create_user_role(%{user_id: user.id, role_id: role.id, scope: scope}) do
      user
    else
      other -> other
    end
  end

  def delete_users_role(%{} = user, role_name, scope \\ nil) do
    with role when not is_nil(role) <- get_role_by_name(role_name),
         user_role when not is_nil(user_role) <- get_by_user_role(user.id, role.id, scope),
         {:ok, _} <- delete_user_role(user_role) do
      :ok
    else
      other ->
        Logger.warn "other: #{inspect other}"
        other
    end
  end

  ##################
  # UserRole

  @doc """
  Returns the list of user_roles.

  ## Examples

      iex> list_user_roles()
      [%UserRole{}, ...]

  """
  def list_user_roles do
    Repo.all(UserRole)
  end

  @doc """
  Get the list of user roles for a given opts.

  Opts must at least contain the `role_id'. If the role is global scope,
  no further options are required. However, if the rooms scope is not global,
  then the scope attribute must be provided.
  """
  def list_by_user_roles(opts) do
    opts
    |> list_by_user_roles_query
    |> Repo.all
  end

  def list_by_user_roles_query(opts) do
    {preload, opts} = Keyword.pop(opts, :preload)

    opts
    |> Enum.reduce(UserRole, fn {k, v}, query ->
      where(query, [b], field(b, ^k) == ^v)
    end)
    |> do_preload(preload)
    |> order_by(asc: :inserted_at)
  end

  defp do_preload(query, nil), do: query
  defp do_preload(query, preload), do: preload(query, ^preload)

  def count_user_roles(role, scope \\ nil)

  def count_user_roles(%{id: role_id, scope: "global"}, nil) do
    Repo.one from ur in UserRole,
      where: ur.role_id == ^role_id,
      select: count(ur.id)
  end

  def count_user_roles(%{id: role_id, scope: "rooms"}, scope) when not is_nil(scope) do
    Repo.one from ur in UserRole,
      where: ur.role_id == ^role_id and ur.scope == ^scope,
      select: count(ur.id)
  end

  def list_user_roles_user_select(field, opts) do
    opts
    |> list_by_user_roles_query
    |> select([ur], field(ur, ^field))
    |> Repo.all
  end
  @doc """
  Gets a single user_role.

  Raises `Ecto.NoResultsError` if the UserRole does not exist.

  ## Examples

      iex> get_user_role!(123)
      %UserRole{}

      iex> get_user_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_role!(id), do: Repo.get!(UserRole, id)

  @doc """
  Gets a user_role by several fields
  """
  def get_by_user_role(opts) do
    Repo.get_by UserRole, opts
  end

  def get_by_user_role(user_id, role_id, nil) do
    get_by_user_role user_id: user_id, role_id: role_id
  end

  def get_by_user_role(user_id, role_id, scope) do
    get_by_user_role user_id: user_id, role_id: role_id, scope: scope
  end

  def get_role_by_name_with_users(role_name, scope \\ nil)

  def get_role_by_name_with_users(role_name, nil) do
    get_role_by_name role_name, preload: [:users]
  end

  def get_role_by_name_with_users(role_name, scope) do
    role = get_role_by_name role_name
    users = get_role_by_name_users role, scope
    Map.put(role, :users, users)
  end

  def get_role_by_name_users(%{} = role, scope) do
    Repo.all from ur in UserRole,
      join: u in User, on: ur.user_id == u.id,
      where: ur.role_id == ^role.id and ur.scope == ^scope,
      order_by: [asc: u.username],
      select: u
  end

  @doc """
  Creates a user_role.

  ## Examples

      iex> create_user_role(%{field: value})
      {:ok, %UserRole{}}

      iex> create_user_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_role(attrs \\ %{}) do
    # if scope = attrs[:scope] do
    #   if list_by_user_roles(user_id: attrs[:user_id], role_id: attrs[:role_id], scope: scope) != [] do
    #     raise "Attempting to add duplication user role " <> inspect(attrs)
    #   end
    # else
    #   if list_by_user_roles(user_id: attrs[:user_id], role_id: attrs[:role_id]) != [] do
    #     raise "Attempting to add duplication user role " <> inspect(attrs)
    #   end
    # end
    %UserRole{}
    |> UserRole.changeset(attrs)
    |> Repo.insert()
    # |> IO.inspect(label: "user role")
  end

  @doc """
  Updates a user_role.

  ## Examples

      iex> update_user_role(user_role, %{field: new_value})
      {:ok, %UserRole{}}

      iex> update_user_role(user_role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_role(%UserRole{} = user_role, attrs) do
    user_role
    |> UserRole.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a UserRole.

  ## Examples

      iex> delete_user_role(user_role)
      {:ok, %UserRole{}}

      iex> delete_user_role(user_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_role(%UserRole{} = user_role) do
    user_role
    |> change_user_role
    |> Repo.delete
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_role changes.

  ## Examples

      iex> change_user_role(user_role)
      %Ecto.Changeset{source: %UserRole{}}

  """
  def change_user_role(%UserRole{} = user_role) do
    UserRole.changeset(user_role, %{})
  end

  ##################
  # Account

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  """
  def get_account(id), do: Repo.get(Account, id)

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Gets an account by one or more fields
  """
  def get_by_account(opts) do
    {preload, opts} = Keyword.pop(opts, :preload, [])
    opts
    |> Enum.reduce(Account, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.one
  end

  @doc """
  Gets a list of accounts by one or more fields.
  """
  def list_by_accounts(opts) do
    {preload, opts} = Keyword.pop(opts, :preload, [])
    opts
    |> Enum.reduce(Account, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.all
  end

  @doc """
  Creates an account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an Account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{source: %Account{}}

  """
  def change_account(%Account{} = account) do
    Account.changeset(account, %{})
  end

  def get_bot_id do
    Repo.one from u in User,
      join: ur in UserRole, on: ur.user_id == u.id,
      join: r in Role, on: r.id == ur.role_id,
      where: r.name ==  "bot",
      select: u.id,
      limit: 1
  end

  def preload_schema(schema, preload) do
    Repo.preload schema, preload
  end

  def has_role?(%User{} =user, role) do
    Enum.any?(user.user_roles, fn
      %{role: %{name: ^role, scope: "global"}} -> true
      _ -> false
    end)
  end

  def has_role?(%User{user_roles: %Ecto.Association.NotLoaded{}} = user, role, scope) do
    user
    |> Repo.preload([:roles, user_roles: :role])
    |> has_role?(role, scope)
  end

  def has_role?(user, role_name, scope) do
    Enum.any?(user.user_roles, fn
      %{role: %{name: ^role_name}, scope: ^scope} -> true
      _ -> false
    end)
  end

  alias UcxUcc.Accounts.PhoneNumber

  @doc """
  Returns the list of phone_numbers.

  ## Examples

      iex> list_phone_numbers()
      [%PhoneNumber{}, ...]

  """
  def list_phone_numbers do
    Repo.all(PhoneNumber)
  end


  @doc """
  Gets a single phone_number.

  Raises `Ecto.NoResultsError` if the Phone number does not exist.

  ## Examples

      iex> get_phone_number!(123)
      %PhoneNumber{}

      iex> get_phone_number!(456)
      ** (Ecto.NoResultsError)

  """
  def get_phone_number!(id), do: Repo.get!(PhoneNumber, id)

  @doc """
  Creates a phone_number.

  ## Examples

      iex> create_phone_number(%{field: value})
      {:ok, %PhoneNumber{}}

      iex> create_phone_number(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_phone_number(attrs \\ %{}) do
    %PhoneNumber{}
    |> PhoneNumber.changeset(attrs)
    |> Repo.insert()
  end

  def create_phone_number!(attrs \\ %{}) do
    %PhoneNumber{}
    |> PhoneNumber.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a phone_number.

  ## Examples

      iex> update_phone_number(phone_number, %{field: new_value})
      {:ok, %PhoneNumber{}}

      iex> update_phone_number(phone_number, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_phone_number(%PhoneNumber{} = phone_number, attrs) do
    phone_number
    |> PhoneNumber.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PhoneNumber.

  ## Examples

      iex> delete_phone_number(phone_number)
      {:ok, %PhoneNumber{}}

      iex> delete_phone_number(phone_number)
      {:error, %Ecto.Changeset{}}

  """
  def delete_phone_number(%PhoneNumber{} = phone_number) do
    Repo.delete(phone_number)
  end

  def change_phone_number do
    PhoneNumber.changeset(%PhoneNumber{}, %{})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking phone_number changes.

  ## Examples

      iex> change_phone_number(phone_number)
      %Ecto.Changeset{source: %PhoneNumber{}}

  """
  def change_phone_number(%PhoneNumber{} = phone_number) do
    change_phone_number(phone_number, %{})
  end

  def change_phone_number(%{} = attrs) do
    change_phone_number(%PhoneNumber{}, attrs)
  end

  def change_phone_number(%PhoneNumber{} = phone_number, attrs) do
    PhoneNumber.changeset(phone_number, attrs)
  end

  alias UcxUcc.Accounts.PhoneNumberLabel

  @doc """
  Returns the list of phone number labels.

  ## Examples

      iex> list_phone_number_labels()
      [%PhoneNumberLabel{}, ...]

  """
  def list_phone_number_labels do
    Repo.all(PhoneNumberLabel)
  end

  @doc """
  Gets a single phone_number_label.

  Raises `Ecto.NoResultsError` if the Phone number label does not exist.

  ## Examples

      iex> get_phone_number_label!(123)
      %PhoneNumberLabel{}

      iex> get_phone_number_label!(456)
      ** (Ecto.NoResultsError)

  """
  def get_phone_number_label!(id), do: Repo.get!(PhoneNumberLabel, id)

  @doc """
  Creates a phone_number_label.

  ## Examples

      iex> create_phone_number_label(%{field: value})
      {:ok, %PhoneNumberLabel{}}

      iex> create_phone_number_label(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_phone_number_label(attrs \\ %{}) do
    %PhoneNumberLabel{}
    |> PhoneNumberLabel.changeset(to_map attrs)
    |> Repo.insert()
  end

  def create_phone_number_label!(attrs \\ %{}) do
    %PhoneNumberLabel{}
    |> PhoneNumberLabel.changeset(to_map attrs)
    |> Repo.insert!()
  end


  @doc """
  Updates a phone_number_label.

  ## Examples

      iex> update_phone_number_label(phone_number_label, %{field: new_value})
      {:ok, %PhoneNumberLabel{}}

      iex> update_phone_number_label(phone_number_label, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_phone_number_label(%PhoneNumberLabel{} = phone_number_label, attrs) do
    phone_number_label
    |> PhoneNumberLabel.changeset(to_map attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PhoneNumberLabel.

  ## Examples

      iex> delete_phone_number_label(phone_number_label)
      {:ok, %PhoneNumberLabel{}}

      iex> delete_phone_number_label(phone_number_label)
      {:error, %Ecto.Changeset{}}

  """
  def delete_phone_number_label(%PhoneNumberLabel{} = phone_number_label) do
    Repo.delete(phone_number_label)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking phone_number_label changes.

  ## Examples

      iex> change_phone_number_label(phone_number_label)
      %Ecto.Changeset{source: %PhoneNumberLabel{}}

  """
  def change_phone_number_label(%PhoneNumberLabel{} = phone_number_label) do
    PhoneNumberLabel.changeset(phone_number_label, %{})
  end

  # TODO: Replace this hack with the broadcast stuff
  alias UccChat.{Channel}
  alias UccChat.Schema.Subscription, as: SubscriptionSchema
  alias UccChat.Schema.Channel, as: ChannelSchema

  def deactivate_user(user) do
    (from s in SubscriptionSchema,
      join: c in ChannelSchema, on: s.channel_id == c.id,
      where: c.type == 2 and s.user_id == ^(user.id),
      select: c)
    |> Repo.all
    |> Enum.each(fn channel ->
      Channel.update(channel, %{active: false})
    end)
    user
  end

  def activate_user(user) do
    (from s in SubscriptionSchema,
      join: c in ChannelSchema, on: s.channel_id == c.id,
      where: c.type == 2 and s.user_id == ^(user.id),
      select: c)
    |> Repo.all
    |> Enum.each(fn channel ->
      Channel.update(channel, %{active: true})
    end)
    user
  end

  defp to_map(%{} = attrs), do: attrs
  defp to_map(nil), do: %{}
  defp to_map(attrs), do: Enum.into(attrs, %{})

end
