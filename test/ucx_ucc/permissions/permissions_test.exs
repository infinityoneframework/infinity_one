defmodule UcxUcc.PermissionsTest do
  use UcxUcc.DataCase

  alias UcxUcc.{Permissions, Accounts, Repo}

  setup context do
    case context do
      %{integration: true} = _context ->
        setup_integration()
      _-> :ok
    end
  end

  def setup_integration do
    on_exit fn ->
      Permissions.delete_all_objects()
    end
    permissions = [
      %{name: "perm-1", roles: ["admin"] },
      %{name: "perm-2", roles: ["admin", "owner", "user"] },
      %{name: "perm-3", roles: ["admin", "user"] },
      %{name: "perm-4", roles: ["owner", "admin"] },
    ]
    roles = Accounts.create_roles [admin: :global, owner: :rooms, user: :global]
    Permissions.create_permissions permissions, roles
    Permissions.initialize()
    :ok
  end

  describe "Permission" do
    test "creates a permission" do
      {:ok, perm} = Permissions.create_permission(%{name: "perm-one"})
      assert perm.name == "perm-one"
    end
    test "lists permissions" do
      {:ok, _} = Permissions.create_permission(%{name: "perm-one"})
      {:ok, _} = Permissions.create_permission(%{name: "perm-one-1"})
      [p1, p2] = Permissions.list_permissions()
      refute p1.name == p2.name
      assert p1.name in ~w(perm-one perm-one-1)
      assert p2.name in ~w(perm-one perm-one-1)
    end
    test "delete permissions" do
      {:ok, perm} = Permissions.create_permission(%{name: "perm-one"})
      {:ok, _} = Permissions.delete_permission(perm)
      assert Permissions.list_permissions() == []
    end
  end

  describe "permission_role" do
    test "creates and deletes a PermissionRole" do
      {:ok, perm} = Permissions.create_permission(%{name: "perm-one"})
      {:ok, role} = Accounts.create_role %{name: "user", scope: "global"}
      {:ok, pr} = Permissions.create_permission_role(
        %{role_id: role.id, permission_id: perm.id})
      pr = Repo.preload pr, [:role, :permission]
      assert pr.role.name == "user"
      assert pr.permission.name == "perm-one"

      {:ok, _} = Permissions.delete_permission_role(pr)
      assert Permissions.list_permission_roles() == []
    end
  end

  describe "integrate tests" do
    test "users with roles and permissions" do
      {:ok, user} = Accounts.create_user(%{name: "one", email: "one@one",
        username: "one", password: "test", password_confirmation: "test"})
      {:ok, role} = Accounts.create_role %{name: "user", scope: "global"}
      {:ok, _} = Accounts.create_user_role(
        %{user_id: user.id, role_id: role.id})
      {:ok, perm1} = Permissions.create_permission(%{name: "perm-one"})
      {:ok, perm2} = Permissions.create_permission(%{name: "perm-two"})
      {:ok, _} = Permissions.create_permission_role(
        %{role_id: role.id, permission_id: perm1.id})
      {:ok, _} = Permissions.create_permission_role(
        %{role_id: role.id, permission_id: perm2.id})

      user = user.id |> Accounts.get_user! |> Repo.preload([roles: :permissions])
      permission_names =
        user.roles
        |> Enum.map(& &1.permissions)
        |> List.flatten
        |> Enum.map(& &1.name)

      assert length(permission_names) == 2
      assert "perm-one" in permission_names
      assert "perm-two" in permission_names
    end

  end

  describe "integeration" do
    @tag integration: true
    test "query permission" do
      u1 = insert_user()
      refute Permissions.has_permission?(u1, "perm-1")
      assert Permissions.has_permission?(u1, "perm-2")
      assert Permissions.has_permission?(u1, "perm-3")
    end

    @tag integration: true
    test "has at least 1 permission" do
      u1 = insert_user()
      refute Permissions.has_at_least_one_permission?(u1, ~w(perm-1))
      assert Permissions.has_at_least_one_permission?(u1, ~w(perm-1 perm-3))
    end

    @tag integration: true
    test "three" do
      u = insert_user()
      user =
        insert_user()
        |> Accounts.set_users_role("owner", u.id)
      user2 =
        insert_user()
        |> Accounts.set_users_role("admin", nil)

      user = Accounts.get_user user.id, preload: [:roles, user_roles: :role]
      user2 = Accounts.get_user user2.id, preload: [:roles, user_roles: :role]

      assert Permissions.has_permission?(user, "perm-4", u.id)
      refute Permissions.has_permission?(user, "perm-4", user.id)
      assert Permissions.has_permission?(user2, "perm-4", user.id)
    end
  end
end
