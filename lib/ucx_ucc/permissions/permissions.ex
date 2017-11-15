defmodule UcxUcc.Permissions do
  @moduledoc """
  Permissions management.

  Permissions are managed with an ets table that is sync'ed to the
  h/d when changes are made. The frequency of changes should be pretty
  low since that is only done through the admin GUI.

  """
  use GenServer

  import Ecto.{Query, Changeset}, warn: false

  alias UcxUcc.{Accounts, Permissions, Repo}
  alias Permissions.{Permission, PermissionRole}
  # alias Accounts.{User, Role}

  @name __MODULE__

  #################
  # Public API

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def initialize do
    GenServer.cast @name, {:initialize, list_permissions()}
  end

  def delete_all_objects do
    GenServer.cast @name, :delete_all_objects
  end

  def all do
    GenServer.call @name, :all
  end

  def has_permission?(user, permission, scope \\ nil) do
    GenServer.call @name, {:has_permission?, user, permission, scope}
  end

  def has_at_least_one_permission?(user, list) do
    GenServer.call @name, {:has_at_least_one_permission?, user, list}
  end

  def add_role_to_permission(permission, role) do
    GenServer.call @name, {:add_roll_to_permission, permission, role}
  end

  def remove_role_from_permission(permission, role) do
    GenServer.call @name, {:remove_role_from_permission, permission, role}
  end

  def room_type(0), do: "c"
  def room_type(1), do: "p"
  def room_type(2), do: "d"

  #################
  # Callbacks

  def init(_) do
    spawn &startup/0
    {:ok, init_state()}
  end

  defp startup do
    :timer.sleep 10
    initialize()
  end

  def init_state, do: %{permissions: %{}, roles: %{}}

  #################
  # Casts

  def handle_cast({:initialize, permissions}, state) do
    Enum.reduce(permissions, state, fn %{name: permission, roles: roles}, acc ->
      roles = Enum.map(roles, &(&1.name))
      Enum.reduce(roles, put_in(acc, [:permissions, permission], roles), fn role, acc ->
        update_in(acc, [:roles, role], fn
          nil -> [permission]
          list -> [permission | list]
        end)
      end)
    end)
    |> noreply
  end

  def handle_cast(:delete_all_objects, _state) do
    noreply init_state()
  end

  #################
  # Calls

  def handle_call(:all, _, state) do
    state[:permissions]
    |> Map.to_list
    |> Enum.sort
    |> reply(state)
  end

  def handle_call({:has_permission?, user, permission, scope}, _, state) do
    state
    |> do_has_permission?(user, permission, scope)
    |> reply(state)
  end

  def handle_call({:has_at_least_one_permission?, user, list}, _, state) do
    list
    |> Enum.any?(&do_has_permission?(state, user, &1, nil))
    |> reply(state)
  end

  def handle_call({:add_roll_to_permission, permission, role}, state) do
    case create_permission_role(permission, role) do
      {:ok, _}    -> {:ok, do_add_role_to_permission(state, permission, role)}
      {:error, _} -> {:error, state}
    end
    |> reply
  end

  def handle_call({:remove_role_from_permission, permission, role}, state) do
    with pr when not is_nil(pr) <- get_permission_role(permission, role),
         {:ok, _} <- delete_permission_role(pr) do
      {:ok, do_remove_role_from_permission(state, permission, role)}
    else
      _ ->
        {:error, state}
    end
    |> reply
  end

  #################
  # Private

  defp do_add_role_to_permission(state, permission, role) do
    update_in state, [:roles, role], fn list ->
      if permission in list, do: list, else: [permission | list]
    end
  end

  defp do_remove_role_from_permission(state, permission, role) do
    update_in state, [:roles, role], fn list -> List.delete list, permission end
  end

  defp do_has_permission?(state, user, permission, scope) do
    roles = state[:permissions][permission] || []
    Enum.any?(user.user_roles, fn %{role: role, scope: value} ->
      role.name in roles and (role.scope == "global" or value == scope)
    end)
  end
  # defp do_has_permission?(state, user, permission, scope) do
  #   roles = state[:permissions][permission] || []
  #   Enum.any?(user.roles, fn %{name: name, scope: value} ->
  #     name in roles and (value == "global" or value == scope)
  #   end)
  # end

  ##################
  # Permission

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions do
    Repo.all from p in Permission, preload: [:roles]
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permission!(123)
      %Permission{}

      iex> get_permission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  @doc """
  Get a permission by its name.
  """
  def get_permission_by_name(permission) do
    Repo.one from p in Permission, where: p.name == ^permission
  end

  @doc """
  Creates a permission.

  ## Examples

      iex> create_permission(%{field: value})
      {:ok, %Permission{}}

      iex> create_permission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a permission.

  ## Examples

      iex> update_permission(permission, %{field: new_value})
      {:ok, %Permission{}}

      iex> update_permission(permission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Permission.

  ## Examples

      iex> delete_permission(permission)
      {:ok, %Permission{}}

      iex> delete_permission(permission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking permission changes.

  ## Examples

      iex> change_permission(permission)
      %Ecto.Changeset{source: %Permission{}}

  """
  def change_permission(%Permission{} = permission) do
    Permission.changeset(permission, %{})
  end

  @doc """
  Creates permissions.

  ## Examples

      iex> create_permissions([%{name: "one", roles: ~w(admin user)}]


  """
  def create_permissions(permissions, roles_list) do
    permissions
    |> Enum.each(fn %{name: name, roles: roles} ->
      {:ok, permission} = create_permission(%{name: name})
      roles
      |> Enum.each(fn role_name ->
        create_permission_role(%{permission_id: permission.id, role_id: roles_list[role_name]})
      end)
    end)
  end

  ##################
  # PermissionRole

  @doc """
  List a permission_rolese.

  ## Examples

      iex> list_permission_roles()
      [%PermissionRole{}, ...]

  """
  def list_permission_roles do
    Repo.all(PermissionRole)
  end

  @doc """
  Creates a permission role.

  ## Examples

      iex> create_permission_role(%{field: value})
      {:ok, %PermissionRole{}}

      iex> create_permission_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_permission_role(attrs \\ %{}) do
    %PermissionRole{}
    |> PermissionRole.changeset(attrs)
    |> Repo.insert()
  end
  def create_permission_role(permission, role) when is_nil(permission) or is_nil(role) do
    {:error, nil}
  end
  def create_permission_role(permission, role) when is_binary(permission) do
    create_permission_role  get_permission_by_name(permission), role
  end
  def create_permission_role(permission, role) when is_binary(role) do
    create_permission_role  permission, Accounts.get_role_by_name(role)
  end
  def create_permission_role(permission, role) when is_binary(role) do
    create_permission_role(%{permission_id: permission.id, role_id: role.id})
  end

  @doc """
  Deletes a Permission role.

  ## Examples

      iex> delete_permission_role(permission_role)
      {:ok, %PermissionRole{}}

      iex> delete_permission_role(permission_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_permission_role(%PermissionRole{} = permission_role) do
    Repo.delete(permission_role)
  end

  @doc """
  Get a permission Role.

  ## Examples

      iex> get_permission_role("permission" ,"role")
      %PermissionRole{}

      iex> get_permission_role(%Permission{id: id, ...} ,"role")
      %PermissionRole{}

      iex> get_permission_role("permission" , %Role{id: id, ...})
      %PermissionRole{}

      iex> get_permission_role(nil ,"role")
      nil
  """
  def get_permission_role(permission, role) when is_nil(permission) or is_nil(role) do
    nil
  end
  def get_permission_role(permission, role) when is_binary(permission) do
    get_permission_role get_permission_by_name(permission), role
  end
  def get_permission_role(permission, role) when is_binary(role) do
    get_permission_role permission, Accounts.get_role_by_name(role)
  end
  def get_permission_role(permission, role) when is_binary(role) do
    Repo.one from p in PermissionRole, where: p.permission_id == ^permission.id and
      p.role_id == ^role.id
  end

  defp noreply(state), do: {:noreply, state}

  defp reply(reply, state), do: {:reply, reply, state}
  defp reply({reply, state}), do: {:reply, reply, state}

end
