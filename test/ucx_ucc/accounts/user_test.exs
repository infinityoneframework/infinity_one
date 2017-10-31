defmodule UcxUcc.UserTest do
  use UcxUcc.DataCase

  import UcxUcc.TestHelpers
  alias UcxUcc.Accounts
  alias Accounts.User

  setup do
    insert_roles()
    user = insert_user()
    {:ok, user: user}
  end

  test "has_role? user", %{user: user} do
    assert User.has_role?(user, "user")
    refute User.has_role?(user, "user", "rooms")
  end

  test "has_role? admin", %{user: user} do
    refute User.has_role?(user, "admin")
    admin_role = Accounts.get_role_by_name "admin"
    Accounts.add_role_to_user user, admin_role
    admin = Repo.one from u in User, where: u.id == ^(user.id), preload: [:roles, user_roles: :role]
    assert User.has_role?(admin, "user")
    assert User.has_role?(admin, "admin")
  end
end
