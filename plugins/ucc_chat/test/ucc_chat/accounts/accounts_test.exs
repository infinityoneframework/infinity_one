defmodule UccChat.AccountsTest do
  use UccChat.DataCase

  alias UccChat.TestHelpers, as: Helpers

  alias UccChat.Accounts

  setup do
    Helpers.insert_roles()
    user = Helpers.insert_user()
    {:ok, user: user, account: Helpers.insert_account(user)}
  end

  test "gets_by_user_id", %{user: user, account: account} do
    account1 = Accounts.get_account_by_user_id(user.id)
    assert account1.user_id == user.id
    assert account1.id == account.id

    account1 = Accounts.get_account_by_user_id(user.id, preload: [:user])
    assert account1.user.id == user.id
  end
end
