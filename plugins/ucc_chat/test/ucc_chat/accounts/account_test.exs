defmodule UccChat.Accounts.AccountTest do
  use ExUnit.Case, async: true

  alias UcxUcc.Accounts.Account

  test "insert changeset" do
    account = %Account{}
    assert account.view_mode == 1
    assert account.emoji_tone == 0

    changeset = Account.changeset account,
      %{
        user_id: "fd601558-9502-4672-a3cb-1ce59e4ebca1",
        view_mode: 2,
        emoji_tone: 1
      }

    assert changeset.valid?
    assert changeset.changes == %{
      user_id: "fd601558-9502-4672-a3cb-1ce59e4ebca1",
      view_mode: 2,
      emoji_tone: 1,
    }
  end

end
