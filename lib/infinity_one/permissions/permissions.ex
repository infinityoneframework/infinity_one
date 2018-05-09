defmodule InfinityOne.Permissions do
  @moduledoc """
  Permissions management.

  Permissions are managed with an ets table that is sync'ed to the
  h/d when changes are made. The frequency of changes should be pretty
  low since that is only done through the admin GUI.

  """
  use GenServer

  import Ecto.{Query, Changeset}, warn: false

  alias InfinityOne.{Accounts, Permissions, Repo}
  alias Permissions.{Permission, PermissionRole}
  # alias Accounts.{User, Role}
  require Logger

  @name __MODULE__

  #################
  # Public API

  def start_link do
    GenServer.start_link @name, [], name: @name
  end

  def initialize do
    GenServer.cast @name, :initialize
  end

  def initialize(permissions_list) do
    GenServer.cast(@name, {:initialize, permissions_list})
  end

  def delete_all_objects do
    GenServer.cast @name, :delete_all_objects
  end

  def all do
    GenServer.call @name, :all
  end

  def state do
    GenServer.call @name, :state
  end

  def state(permission) do
    GenServer.call @name, {:state, permission}
  end

  def state_role(role_name) do
    GenServer.call @name, {:state_role, role_name}
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

  def toggle_role_on_permission(permission, role_name) when is_binary(permission) do
    permission
    |> get_permission_by_name
    |> toggle_role_on_permission(role_name)
  end

  def toggle_role_on_permission(permission, role_name) do
    if has_role? permission, role_name do
      remove_role_from_permission permission, role_name
    else
      add_role_to_permission permission, role_name
    end
  end

  def has_role?(permission, role_name) do
    role_name in Enum.map(permission.roles, & &1.name)
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

  defp initialize_permissions(permissions_list, state) do
    Enum.reduce(permissions_list, state, fn %{name: permission, roles: roles}, acc ->
      roles = Enum.map(roles, &(&1.name))
      Enum.reduce(roles, put_in(acc, [:permissions, permission], roles), fn role, acc ->
        update_in(acc, [:roles, role], fn
          nil -> [permission]
          list -> [permission | list]
        end)
      end)
    end)
  end

  #################
  # Casts

  def handle_cast(:initialize, state) do
    add_missing_permissions()

    list_permissions()
    |> initialize_permissions(state)
    |> noreply
  end

  def handle_cast({:initialize, permissions_list}, state) do
    permissions_list
    |> initialize_permissions(state)
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

  def handle_call(:state, _, state) do
    reply state, state
  end

  def handle_call({:state, permission}, _, state) do
    reply state.permissions[permission], state
  end

  def handle_call({:state_role, role_name}, _, state) do
    reply state.roles[role_name], state
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

  def handle_call({:add_roll_to_permission, permission, role}, _, state) do
    case create_permission_role(permission, role) do
      {:ok, _}    -> {:ok, do_add_role_to_permission(state, permission, role)}
      {:error, _} -> {:error, state}
    end
    |> reply
  end

  def handle_call({:remove_role_from_permission, permission, role}, _, state) do
    with pr when not is_nil(pr) <- get_permission_role(permission, role),
         {:ok, _} <- delete_permission_role(pr) do
      {:ok, do_remove_role_from_permission(state, permission, role)}
    else
      _ ->
        {:error, state}
    end
    |> reply
  end

  def handle_info({"accounts", "role:new", _payload}, state) do
    # Logger.warn "payload: " <> inspect(payload)
    noreply state
  end

  #################
  # Private

  defp do_add_role_to_permission(state, %{} = permission, role) do
    do_add_role_to_permission(state, permission.name, role)
  end
  defp do_add_role_to_permission(state, permission, %{} = role) do
    do_add_role_to_permission(state, permission, role.name)
  end
  defp do_add_role_to_permission(state, permission, role) do
    state
    |> update_in([:roles, role], fn list ->
      if permission in list, do: list, else: [permission | list]
    end)
    |> update_in([:permissions, permission], fn list ->
      if role in list, do: list, else: [role | list]
    end)
  end

  defp do_remove_role_from_permission(state, %{} = permission, role) do
    do_remove_role_from_permission(state, permission.name, role)
  end
  defp do_remove_role_from_permission(state, permission, %{} = role) do
    do_remove_role_from_permission(state, permission, role.name)
  end
  defp do_remove_role_from_permission(state, permission, role) do
    state
    |> update_in([:roles, role], fn list -> List.delete list, permission end)
    |> update_in([:permissions, permission], fn list -> List.delete list, role end)
  end

  defp do_has_permission?(state, user, permission, scope) do
    roles =
      case state[:permissions][permission] do
        nil ->
          default_permission_roles(permission)
        roles ->
          roles
      end

    Enum.any?(user.user_roles, fn %{role: role, scope: value} ->
      role.name in roles and (role.scope == "global" or value == scope)
    end)
  end

  ##################
  # Permission

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions do
    # add_missing_permissions()
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
  def get_permission!(id) do
    Repo.get!(Permission, id)
  end


  @doc """
  Get a permission by its name.
  """
  def get_permission_by_name(permission) do
    Repo.one from p in Permission, where: p.name == ^permission, preload: [:roles]
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

  def change_permission_roles(attrs \\ %{})

  def change_permission_roles(%PermissionRole{} = pr) do
    change_permission_roles pr, %{}
  end

  def change_permission_roles(attrs) do
    change_permission_roles %PermissionRole{}, attrs
  end

  def change_permission_roles(pr, attrs) do
    PermissionRole.changeset(pr, attrs)
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
  def create_permission_role(permission, role) do
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
  def get_permission_role(permission, role) do
    Repo.one from p in PermissionRole, where: p.permission_id == ^permission.id and
      p.role_id == ^role.id
  end

  defp noreply(state), do: {:noreply, state}

  defp reply(reply, state), do: {:reply, reply, state}
  defp reply({reply, state}), do: {:reply, reply, state}


  @doc """
  Find any permission in `default_permissions/0` missing and add them.

  Adds any new permissions that have been added in new version updates
  and add them to the database.
  """
  def add_missing_permissions do
    defaults = default_permissions()
    all_names = get_names(defaults)
    current_names = get_names list_permissions()

    do_add_missing_permissions defaults, all_names -- current_names
  end

  defp  do_add_missing_permissions(_, []), do: []

  defp  do_add_missing_permissions(defaults, new_names) do
    # create hash for the defaults by name
    defaults_roles = for perm <- defaults, into: %{}, do: {perm.name, perm.roles}

    # lookup hash to get the role_id from its name
    roles_map =
      Accounts.list_roles()
      |> Enum.map(& {&1.name, &1.id})
      |> Enum.into(%{})

    Enum.map(new_names, fn name ->
      # mapping the missing permission names here
      {:ok, permission} = create_permission(%{name: name})

      defaults_roles[name]
      |> Enum.each(fn role_name ->
        create_permission_role(%{permission_id: permission.id, role_id: roles_map[role_name]})
      end)
      name
    end)
  end

  defp get_names(list) do
    Enum.map(list, & &1.name)
  end

  @doc """
  Get the roles from the default permissions for a given permission name.

  Returns the role name list if found, otherwise []
  """
  def default_permission_roles(name) do
    default_permissions()
    |> Enum.find(%{}, & &1.name == name)
    |> Map.get(:name, [])
  end

  # def admin_permissions do
  #   default_permissions()
  #   |> Enum.filter(& &1.roles == ["admin"])
  #   |> Enum.map(& &1.name)
  # end

  @doc """
  List of all the permissions and their default values.
  """
  def default_permissions, do: [
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
    %{name: "invite-user",                   roles: ["admin", "user", "bot"] },
    %{name: "manage-assets",                 roles: ["admin"] },
    %{name: "manage-emoji",                  roles: ["admin"] },
    %{name: "manage-integrations",           roles: ["admin"] },
    %{name: "manage-own-integrations",       roles: ["admin", "bot"] },
    %{name: "manage-oauth-apps",             roles: ["admin"] },
    %{name: "mention-all",                   roles: ["admin", "owner", "moderator", "user"] },
    %{name: "mention-here",                  roles: ["admin", "owner", "moderator", "user"] },
    %{name: "mention-all!",                  roles: ["admin"] },
    %{name: "mute-user",                     roles: ["admin", "owner", "moderator"] },
    %{name: "pin-message",                   roles: ["admin", "owner", "moderator"] },
    %{name: "preview-c-room",                roles: ["admin", "user"] },
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
    %{name: "view-accounts-administration",  roles: ["admin"] },
    %{name: "view-general-administration",   roles: ["admin"] },
    %{name: "view-webrtc-administration",    roles: ["admin"] },
    %{name: "view-layout-administration",    roles: ["admin"] },
    %{name: "view-phone-numbers-administration",  roles: ["admin"] },
    %{name: "view-backup-restore-administration", roles: ["admin"] },
    %{name: "view-file-upload-administration",    roles: ["admin"] },
    %{name: "create-page",                   roles: ["admin", "user", "bot"] },
    %{name: "view-page",                     roles: ["admin", "user", "bot"] },
    %{name: "view-p-page",                   roles: ["admin", "user", "bot"] },
    %{name: "edit-page",                     roles: ["admin", "user"] },
    %{name: "remove-page",                   roles: ["admin", "p-owner", "p-moderator"] },
    %{name: "view-pages-administration",     roles: ["admin"] },
  ]

  def show_permission_list do
    [
      "access-permissions",
      "add-user-to-joined-room",
      "add-user-to-any-c-room",
      "add-user-to-any-p-room",
      "archive-room",
      "assign-admin-role",
      "ban-user",
      "bulk-register-user",
      "create-c",
      "create-d",
      "create-p",
      "create-user",
      "clean-channel-history",
      "delete-c",
      "delete-d",
      "delete-message",
      "delete-p",
      "delete-user",
      "edit-message",
      "edit-other-user-info",
      "edit-other-user-password",
      "edit-room",
      "invite-user",
      "mention-all",
      "mention-here",
      "mention-all!",
      "mute-user",
      "pin-message",
      "preview-c-room",
      "set-moderator",
      "set-owner",
      "unarchive-room",
      "view-c-room",
      "view-history",
      "view-joined-room",
      "view-other-user-channels",
      "view-p-room",
      "view-statistics",
      "view-room-administration",
      "view-message-administration",
      "view-user-administration",
      "view-accounts-administration",
      "view-general-administration",
      "view-webrtc-administration",
      "view-layout-administration",
      "view-phone-numbers-administration",
      "view-backup-restore-administration",
      "view-file-upload-administration",
      # "create-page",
      # "view-page",
      # "view-p-page",
      # "edit-page",
      # "remove-page",
      "view-pages-administration",
    ]
  end

end
