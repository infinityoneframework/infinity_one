defmodule InfinityOne.AccountsTest do
  use InfinityOne.DataCase

  alias InfinityOne.Accounts

  @id "345bf613-5a44-42d0-9ac4-34562be96f84"
  @id2 "345bf613-5a44-42d0-9ac4-34562be96f85"

  describe "users" do
    alias InfinityOne.Accounts.Role
    alias InfinityOne.Accounts.User

    test "add_role_to_user" do
      _user_role = insert_role "user", %{scope: "global"}
      admin_role = insert_role "admin", %{scope: "global"}
      user = insert_user()
      [role] = user.roles
      assert role.name == "user"
      Accounts.add_role_to_user user, admin_role
      user = Repo.one from u in User, where: u.id == ^(user.id), preload: [:roles, user_roles: :role]
      names = Enum.map user.roles, &(&1.name)
      assert "user" in names
      assert "admin" in names
    end

    test "add_role_to_user name" do
      insert_role "user", %{scope: "global"}
      insert_role "admin", %{scope: "global"}
      user = insert_user()
      Accounts.add_role_to_user user, "admin"
      user = Repo.one from u in User, where: u.id == ^(user.id), preload: [:roles, user_roles: :role]
      names = Enum.map user.roles, &(&1.name)
      assert "user" in names
      assert "admin" in names
    end
  end

  describe "roles" do
    alias InfinityOne.Accounts.Role

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

    test "set_users_role" do
      _admin_role = insert_role "admin", %{scope: "global"}
      _owner_role = insert_role "owner", %{scope: "rooms"}
      id = insert_user() |> Map.get(:id)
      user =
        insert_user()
        |> Accounts.set_users_role("admin", nil)
        |> Accounts.set_users_role("owner", id)

      user = Accounts.get_user user.id, preload: [user_roles: :role]

      urs = user.user_roles

      assert length(urs) == 3
      assert Enum.find(urs, & &1.role.name == "owner") |> Map.get(:scope) == id
      assert Enum.find(urs, & &1.role.name == "user") |> Map.get(:scope) |> is_nil
      assert Enum.find(urs, & &1.role.name == "admin") |> Map.get(:scope) |> is_nil
    end

    test "delete_users_role" do
      _admin_role = insert_role "admin", %{scope: "global"}
      _owner_role = insert_role "owner", %{scope: "rooms"}
      id = insert_user() |> Map.get(:id)
      user =
        insert_user()
        |> Accounts.set_users_role("admin", nil)
        |> Accounts.set_users_role("owner", id)

      user = Accounts.get_user user.id, preload: [user_roles: :role]

      :ok = Accounts.delete_users_role(user, "owner", id)
      :ok = Accounts.delete_users_role(user, "admin", nil)

      nil = Accounts.delete_users_role(user, "owner", user.id)

      user = Accounts.get_user user.id, preload: [user_roles: :role]
      assert length(user.user_roles) == 1
    end
  end

  describe "phone_numbers" do
    alias InfinityOne.Accounts.{PhoneNumber, PhoneNumberLabel}

    @valid_attrs %{number: "12345", primary: true, type: "some type", label_id: @id}
    @update_attrs %{number: "5555", primary: false, type: "some updated type", label_id: @id2}
    @invalid_attrs %{number: nil, primary: nil, type: nil, label_id: nil}

    def phone_number_fixture(attrs \\ %{}) do
      {:ok, label} = Accounts.create_phone_number_label(%{name: "Work"})
      user = insert_user()
      {:ok, phone_number} =
        attrs
        |> Enum.into(%{label_id: label.id})
        |> Enum.into(%{user_id: user.id})
        |> Enum.into(@valid_attrs)
        |> Accounts.create_phone_number()

      phone_number
    end

    test "list_phone_numbers/0 returns all phone_numbers" do
      phone_number = phone_number_fixture()
      assert Accounts.list_phone_numbers() == [phone_number]
    end

    test "get_phone_number!/1 returns the phone_number with given id" do
      phone_number = phone_number_fixture()
      assert Accounts.get_phone_number!(phone_number.id) == phone_number
    end

    test "create_phone_number/1 with valid data creates a phone_number" do
      {:ok, label} = Accounts.create_phone_number_label(%{name: "Work"})
      user = insert_user()
      attrs =
        @valid_attrs
        |> Map.put(:label_id, label.id)
        |> Map.put(:user_id, user.id)

      assert {:ok, %PhoneNumber{} = phone_number} = Accounts.create_phone_number(attrs)
      assert phone_number.number == "12345"
      assert phone_number.primary == true
      assert phone_number.type == "some type"
      assert phone_number.label_id == label.id
    end

    test "create_phone_number/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_phone_number(@invalid_attrs)
    end

    test "update_phone_number/2 with valid data updates the phone_number" do
      {:ok, label} = Accounts.create_phone_number_label(%{name: "Home"})
      phone_number = phone_number_fixture()
      user = insert_user()
      attrs =
        @update_attrs
        |> Map.put(:label_id, label.id)
        |> Map.put(:user_id, user.id)
      assert {:ok, phone_number} = Accounts.update_phone_number(phone_number, attrs)
      assert %PhoneNumber{} = phone_number
      assert phone_number.number == "5555"
      assert phone_number.primary == false
      assert phone_number.type == "some updated type"
      assert phone_number.label_id == label.id
    end

    test "update_phone_number/2 with invalid data returns error changeset" do
      phone_number = phone_number_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_phone_number(phone_number, @invalid_attrs)
      assert phone_number == Accounts.get_phone_number!(phone_number.id)
    end

    test "delete_phone_number/1 deletes the phone_number" do
      phone_number = phone_number_fixture()
      assert {:ok, %PhoneNumber{}} = Accounts.delete_phone_number(phone_number)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_phone_number!(phone_number.id) end
    end

    test "change_phone_number/1 returns a phone_number changeset" do
      phone_number = phone_number_fixture()
      assert %Ecto.Changeset{} = Accounts.change_phone_number(phone_number)
    end
  end

  describe "phone_number_labels" do
    alias InfinityOne.Accounts.PhoneNumberLabel

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def phone_number_label_fixture(attrs \\ %{}) do
      {:ok, phone_number_label} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_phone_number_label()

      phone_number_label
    end

    test "list_phone_number_labels/0 returns all phone_number_labels" do
      phone_number_label = phone_number_label_fixture()
      assert Accounts.list_phone_number_labels() == [phone_number_label]
    end

    test "get_phone_number_label!/1 returns the phone_number_label with given id" do
      phone_number_label = phone_number_label_fixture()
      assert Accounts.get_phone_number_label!(phone_number_label.id) == phone_number_label
    end

    test "create_phone_number_label/1 with valid data creates a phone_number_label" do
      assert {:ok, %PhoneNumberLabel{} = phone_number_label} = Accounts.create_phone_number_label(@valid_attrs)
      assert phone_number_label.name == "some name"
    end

    test "create_phone_number_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_phone_number_label(@invalid_attrs)
    end

    test "update_phone_number_label/2 with valid data updates the phone_number_label" do
      phone_number_label = phone_number_label_fixture()
      assert {:ok, phone_number_label} = Accounts.update_phone_number_label(phone_number_label, @update_attrs)
      assert %PhoneNumberLabel{} = phone_number_label
      assert phone_number_label.name == "some updated name"
    end

    test "update_phone_number_label/2 with invalid data returns error changeset" do
      phone_number_label = phone_number_label_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_phone_number_label(phone_number_label, @invalid_attrs)
      assert phone_number_label == Accounts.get_phone_number_label!(phone_number_label.id)
    end

    test "delete_phone_number_label/1 deletes the phone_number_label" do
      phone_number_label = phone_number_label_fixture()
      assert {:ok, %PhoneNumberLabel{}} = Accounts.delete_phone_number_label(phone_number_label)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_phone_number_label!(phone_number_label.id) end
    end

    test "change_phone_number_label/1 returns a phone_number_label changeset" do
      phone_number_label = phone_number_label_fixture()
      assert %Ecto.Changeset{} = Accounts.change_phone_number_label(phone_number_label)
    end
  end
end
