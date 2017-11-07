defmodule UcxUcc.UserTest do
  use UcxUcc.DataCase

  import UcxUcc.TestHelpers
  # alias UcxUcc.Accounts
  # alias Accounts.User

  setup do
    insert_roles()
    user = insert_user()
    {:ok, user: user}
  end

end
