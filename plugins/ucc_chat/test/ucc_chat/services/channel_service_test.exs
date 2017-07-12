defmodule UccChat.ChannelServiceTest do
  use UccChat.DataCase

  import UccChat.TestHelpers

  alias UccChat.ChannelService, as: Service

  setup do
    UcxUcc.TestHelpers.insert_role "owner"
    user = UcxUcc.TestHelpers.insert_role_user "user"
    channel = insert_channel user
    {:ok, %{user: user, channel: channel}}
  end

  test "create_subscription", %{user: user, channel: channel} do
    {:ok, sub} = Service.create_subscription channel, user.id
    assert sub.type == 0

    user2 = UcxUcc.TestHelpers.insert_user
    {:ok, sub} = Service.create_subscription channel.id, user2.id
    assert sub.user_id == user2.id
  end

  test "invite_user", %{user: user, channel: channel} do
    user2 = UcxUcc.TestHelpers.insert_user
    {:ok, result} = Service.invite_user user, channel.id, user2.id, channel: false
    assert result == "added"
    [sub] = UccChat.Subscription.list
    assert sub.user_id == user.id
  end

  test "join_channel channel", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    [sub] = UccChat.Subscription.list
    assert sub.user_id == user.id
    assert sub.channel_id == channel.id
  end

  test "join_channel channel_id", %{user: user, channel: channel} do
    Service.join_channel channel.id, user.id, channel: false
    [sub] = UccChat.Subscription.list
    assert sub.user_id == user.id
    assert sub.channel_id == channel.id
  end

  test "set_subscription_state", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    Service.set_subscription_state channel.id, user.id, true
    [sub] = UccChat.Subscription.list
    assert sub.open
    Service.set_subscription_state channel.id, user.id, false
    [sub] = UccChat.Subscription.list
    refute sub.open
  end

  test "set_subscription_state_room", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    Service.set_subscription_state_room channel.name, user.id, true
    [sub] = UccChat.Subscription.list
    assert sub.open
    Service.set_subscription_state_room channel.name, user.id, false
    [sub] = UccChat.Subscription.list
    refute sub.open
  end

end
