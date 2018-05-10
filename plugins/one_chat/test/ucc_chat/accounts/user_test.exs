defmodule OneChat.Accounts.UserTest do
  use OneChat.DataCase

  alias InfinityOne.Accounts.User

  @valid_attrs %{
    username: "username",
    email: "user@example.com",
    name: "User Name",
    password: "secret",
    password_confirmation: "secret",
    subscriptions: []
  }

  @invalid_attrs %{}

  test "insert changeset" do
    user = %User{}

    changeset = User.changeset user,
      Map.put(@valid_attrs, :chat_status, "online")

    assert changeset.errors == []
    assert changeset.valid?
    assert changeset.changes |> Map.delete(:password_hash) |> Map.delete(:account) ==
      Map.put(@valid_attrs, :chat_status, "online")
  end

  test "rejects username all and here" do
    assert User.changeset(%User{}, Map.put(@valid_attrs, :username, "good")).valid?
    refute User.changeset(%User{}, Map.put(@valid_attrs, :username, "all")).valid?
    refute User.changeset(%User{}, Map.put(@valid_attrs, :username, "here")).valid?
  end

  test "rejects invalid attrs" do
    refute User.changeset(%User{}, @invalid_attrs).valid?
  end

end
