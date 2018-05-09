defmodule OneChat.AccountsTest do
  use OneChat.DataCase

  alias OneChat.TestHelpers, as: Helpers

  alias OneChat.Accounts

  setup do
    Helpers.insert_roles()
    user = Helpers.insert_user()
    # {:ok, user: user, account: Helpers.insert_account(user)}
    {:ok, user: user, account: user.account}
  end

  test "gets_by_user_id", %{user: user, account: account} do
    account1 = Accounts.get_account_by_user_id(user.id)
    assert account1.user_id == user.id
    assert account1.id == account.id

    account1 = Accounts.get_account_by_user_id(user.id, preload: [:user])
    assert account1.user.id == user.id
  end

  # test "has_role? user", %{user: user} do
  #   assert Accounts.has_role?(user, "user")
  #   refute Accounts.has_role?(user, "user", "rooms")
  # end

  # test "has_role? admin", %{user: user} do
  #   refute Accounts.has_role?(user, "admin")
  #   admin_role = Accounts.get_role_by_name "admin"
  #   Accounts.add_role_to_user user, admin_role
  #   admin = Repo.one from u in User, where: u.id == ^(user.id), preload: [:roles, user_roles: :role]
  #   assert Accounts.has_role?(admin, "user")
  #   assert Accounts.has_role?(admin, "admin")
  # end
end
