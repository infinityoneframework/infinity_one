defmodule UccChat.ChannelTest do
  use UccChat.DataCase

  alias UccChat.Channel
  alias UccChat.TestHelpers, as: H

  setup do
    H.insert_roles()
    user = H.insert_user
    {:ok,
      user: user,
      channel: H.insert_channel(user),
      account: H.insert_account(user)}
  end

  test "create", %{user: user} do
    {:ok, channel} = Channel.create %{name: "test", user_id: user.id}
    assert channel.user_id == user.id
  end

  test "create!", %{user: user} do
    channel = Channel.create! %{name: "test", user_id: user.id}
    assert channel.user_id == user.id
  end

  test "get", %{channel: channel} do
    c1 = Channel.get(channel.id)
    assert c1.id == channel.id
  end

  test "get preload", %{channel: channel, user: user} do
    c1 = Channel.get(channel.id, preload: [:owner])
    assert c1.id == channel.id
    assert c1.owner.id == user.id
  end

  test "get!", %{channel: channel} do
    c1 = Channel.get!(channel.id)
    assert c1.id == channel.id
  end

  test "get_by", %{channel: channel, user: user} do
    c1 = Channel.get_by(user_id: user.id)
    assert c1.id == channel.id
  end

  test "get_by preload", %{channel: channel, user: user, account: account} do
    c1 = Channel.get_by(user_id: user.id, preload: [owner: :account])
    assert c1.id == channel.id
    assert c1.owner.id == user.id
    assert c1.owner.account.id == account.id
  end

  test "list", %{channel: channel} do
    [c1] = Channel.list()
    assert c1.id == channel.id
  end

  test "first", %{channel: ch1, user: user} do
    H.insert_channel user
    ch = Channel.first()
    assert ch.id == ch1.id
  end

  test "last", %{channel: _ch1, user: user} do
    ch2 = H.insert_channel user
    ch = Channel.last()
    assert ch.id == ch2.id
  end

  test "update", %{channel: ch1} do
    {:ok, ch} = Channel.update ch1, %{topic: "test me"}
    assert ch.topic == "test me"
    assert ch.id == ch1.id
  end

  test "update!", %{channel: ch1} do
    ch = Channel.update! ch1, %{description: "testing"}
    assert ch.description == "testing"
  end

  test "delete id", %{channel: ch1} do
    {:ok, _} = Channel.delete ch1.id
    assert Channel.list() == []
  end

  test "delete schema", %{channel: ch1} do
    {:ok, _} = Channel.delete ch1
    assert Channel.list() == []
  end

  test "delete! id", %{channel: ch1} do
    Channel.delete! ch1.id
    assert Channel.list() == []
  end

  test "delete! id with notifications", %{channel: ch1, account: account} do
    n = H.insert_notification ch1
    H.insert_account_notification account, n
    Channel.delete! ch1.id
    assert Channel.list() == []
  end

  test "delete! schema", %{channel: ch1} do
    Channel.delete! ch1
    assert Channel.list() == []
  end

  test "delete_all", %{channel: _ch1, user: user} do
    H.insert_channel user
    Channel.delete_all
    assert Channel.list() == []
  end
end

