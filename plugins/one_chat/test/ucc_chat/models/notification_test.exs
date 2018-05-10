defmodule OneChat.NotificationTest do
  use OneChat.DataCase

  alias OneChat.Notification
  alias OneChat.TestHelpers, as: H
  alias InfinityOne.Permissions

  setup do
    H.insert_roles()
    user = H.insert_user
    Permissions.initialize_permissions_db()
    Permissions.initialize(Permissions.list_permissions())
    channel = H.insert_channel user
    {:ok, user: user, channel: channel}
  end

  test "create", %{channel: channel} do
    {:ok, notification} = Notification.create %{channel_id: channel.id, settings: %{}}
    assert notification.channel_id == channel.id
  end

  test "create!", %{channel: channel} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    assert notification.channel_id == channel.id
  end

  test "get", %{channel: channel} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    assert H.schema_eq(Notification.get(notification.id), notification)
  end

  test "get preload", %{channel: channel} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    n1 = Notification.get(notification.id, preload: [:channel])
    assert n1.id == notification.id
    assert n1.channel.id == channel.id
  end

  test "get!", %{channel: channel} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    assert H.schema_eq(Notification.get!(notification.id), notification)
  end

  test "get_by", %{channel: channel} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    assert H.schema_eq(Notification.get_by(channel_id: channel.id), notification)
  end

  test "get_by preload", %{channel: channel, user: user} do
    notification = Notification.create! %{channel_id: channel.id, settings: %{}}
    n1 = Notification.get_by(channel_id: channel.id, preload: [channel: :owner])
    assert n1.id == notification.id
    assert n1.channel.id == channel.id
    assert n1.channel.owner.id == user.id
  end

  test "list", %{channel: channel} do
    n1 = Notification.create! %{channel_id: channel.id, settings: %{}}
    [n] = Notification.list()
    assert n1.id == n.id
  end

  # test "first", %{channel: ch1, user: user} do
  #   ch2 = H.insert_channel user
  #   n1 = Notification.create! %{channel_id: ch1.id, settings: %{}}
  #   Process.sleep(1000)
  #   Notification.create! %{channel_id: ch2.id, settings: %{}}
  #   n = Notification.first()
  #   assert n.id == n1.id
  # end

  # test "last", %{channel: ch1, user: user} do
  #   ch2 = H.insert_channel user
  #   Notification.create! %{channel_id: ch1.id, settings: %{}}
  #   Process.sleep(1000)
  #   n2 = Notification.create! %{channel_id: ch2.id, settings: %{}}
  #   n = Notification.last()
  #   assert n.id == n2.id
  # end

  test "update", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{}}
    settings = Map.put(n1.settings, :audio, "preferences") |> Map.from_struct
    {:ok, n} = Notification.update n1, %{settings: settings}
    assert n.id == n1.id
    assert n.settings.audio == "preferences"
  end

  test "update!", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{audio: "test"}}
    assert n1.settings.audio == "test"
    settings = Map.put(n1.settings, :audio, "preferences") |> Map.from_struct
    {:ok, n} = Notification.update n1, %{settings: settings}
    assert n.id == n1.id
    assert n.settings.audio == "preferences"
  end

  test "delete id", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{audio: "test"}}
    {:ok, _} = Notification.delete n1.id
    assert Notification.list() == []
  end

  test "delete schema", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{}}
    {:ok, _} = Notification.delete n1
    assert Notification.list() == []
  end

  test "delete! id", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{}}
    Notification.delete! n1.id
    assert Notification.list() == []
  end

  test "delete! schema", %{channel: ch1} do
    n1 = Notification.create! %{channel_id: ch1.id, settings: %{}}
    Notification.delete! n1
    assert Notification.list() == []
  end

  test "delete_all", %{channel: ch1, user: user} do
    ch2 = H.insert_channel user
    Notification.create! %{channel_id: ch1.id, settings: %{}}
    Notification.create! %{channel_id: ch2.id, settings: %{}}
    Notification.delete_all
    assert Notification.list() == []
  end
end
