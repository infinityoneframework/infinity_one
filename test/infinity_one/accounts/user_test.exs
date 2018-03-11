defmodule InfinityOne.UserTest do
  use InfinityOne.DataCase

  import InfinityOne.TestHelpers
  # alias InfinityOne.Accounts
  # alias Accounts.User

  setup do
    insert_roles()
    user = insert_user()
    {:ok, user: user}
  end

end
