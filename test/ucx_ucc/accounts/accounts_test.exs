defmodule UcxUcc.AccountsTest do
  use UcxUcc.DataCase

  alias UcxUcc.Accounts

  describe "roles" do
    alias UcxUcc.Accounts.Role

    @valid_attrs %{description: "some description", name: "some name", scope: "some scope"}
    @update_attrs %{description: "some updated description", name: "some updated name", scope: "some updated scope"}
    @invalid_attrs %{description: nil, name: nil, scope: nil}

    def role_fixture(attrs \\ %{}) do
      {:ok, role} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_role()

      role
    end

    test "list_roles/0 returns all roles" do
      role = role_fixture()
      Enum.each Accounts.list_roles(), fn r ->
        assert schema_eq(r, role)
      end
    end

    test "get_role!/1 returns the role with given id" do
      role = role_fixture()
      assert schema_eq(Accounts.get_role!(role.id), role)
    end

    test "create_role/1 with valid data creates a role" do
      assert {:ok, %Role{} = role} = Accounts.create_role(@valid_attrs)
      assert role.description == "some description"
      assert role.name == "some name"
      assert role.scope == "some scope"
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_role(@invalid_attrs)
    end

    test "update_role/2 with valid data updates the role" do
      role = role_fixture()
      assert {:ok, role} = Accounts.update_role(role, @update_attrs)
      assert %Role{} = role
      assert role.description == "some updated description"
      assert role.name == "some updated name"
      assert role.scope == "some updated scope"
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = role_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_role(role, @invalid_attrs)
      assert schema_eq(role, Accounts.get_role!(role.id))
    end

    test "delete_role/1 deletes the role" do
      role = role_fixture()
      assert {:ok, %Role{}} = Accounts.delete_role(role)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_role!(role.id) end
    end

    test "change_role/1 returns a role changeset" do
      role = role_fixture()
      assert %Ecto.Changeset{} = Accounts.change_role(role)
    end
  end
end
