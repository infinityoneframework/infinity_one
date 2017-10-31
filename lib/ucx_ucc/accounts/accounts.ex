defmodule UcxUcc.Accounts do

  import Ecto.{Query, Changeset}, warn: false
  alias UcxUcc.Repo

  # alias UcxUcc.Accounts.User
  alias UcxUcc.Accounts.{Role, UserRole, User, Account}
  require Logger
  # alias UcxUcc.Permissions.{Permission, PermissionRole}

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

  def list_users_by_pattern(user_ids, pattern, count \\ 5) do
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

  def list_all_users_by_pattern(pattern, exclude, count) do
    User
    |> where([c], like(c.username, ^pattern) and not c.id in ^exclude)
    |> join(:left, [c], r in assoc(c, :roles))
    |> where([c, r], not(r.name == "bot" and r.scope == "global"))
    |> preload([c, r], [roles: c])
    |> select([c], c)
    |> order_by([c], asc: c.username)
    |> limit(^count)
    |> Repo.all
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)
  def get_user!(id, opts) do
    preload = opts[:preload] || []
    Repo.one! from u in User, where: u.id == ^id, preload: ^preload
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user(id, opts) do
    preload = opts[:preload] || []
    Repo.one from u in User, where: u.id == ^id, preload: ^preload
  end

  def get_by_user(opts) do
    {preload, opts} = Keyword.pop(opts, :preload, [])
    opts
    |> Enum.reduce(User, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.one
  end

  def list_by_user(opts) do
    {preload, opts} = Keyword.pop(opts, :preload, [])
    opts
    |> Enum.reduce(User, fn {k, v}, query ->
      where query, [q], field(q, ^k) == ^v
    end)
    |> preload(^preload)
    |> Repo.all
  end

  def username_by_user_id(id) do
    case get_user id do
      nil -> nil
      user -> user.username
    end
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
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
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

  def add_role_to_user(%User{} = user, %Role{} = role) do
    create_user_role %{user_id: user.id, role_id: role.id}
  end

  def add_role_to_user(%User{} = user, role_name) do
    add_role_to_user user, get_role_by_name(role_name)
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{source: %Role{}}

  """
  def change_role(%Role{} = role) do
    Role.changeset(role, %{})
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
  def get_role_by_name(role) do
    Repo.one from r in Role, where: r.name == ^role
  end

  def set_users_role(%{} = user, role_name, scope) do
    with role when not is_nil(role) <- get_role_by_name(role_name),
         {:ok, _} <- create_user_role(%{user_id: user.id, role_id: role.id, scope: scope}) do
      user
    else
      other -> other
    end
  end

  def delete_users_role(%{} = user, role_name, scope) do
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

  @doc """
  Creates a user_role.

  ## Examples

      iex> create_user_role(%{field: value})
      {:ok, %UserRole{}}

      iex> create_user_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_role(attrs \\ %{}) do
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
    Repo.delete(user_role)
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

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

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
      %{name: ^role, scope: "global"} -> true
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
end
