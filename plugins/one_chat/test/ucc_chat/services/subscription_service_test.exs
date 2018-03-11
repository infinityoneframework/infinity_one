defmodule OneChat.SubscriptionServiceTest do
  use OneChat.DataCase

  import OneChat.TestHelpers

  alias OneChat.Subscription, as: Service

  setup do
    InfinityOne.TestHelpers.insert_role "owner"
    user = InfinityOne.TestHelpers.insert_role_user "user"
    channel = insert_channel user
    sub = insert_subscription user, channel
    {:ok, %{user: user, channel: channel, sub: sub}}
  end

  test "get", %{user: user, channel: channel, sub: sub} do
    subscription = Service.get(channel.id, user.id)
    assert subscription.id == sub.id
  end

  test "get field", %{user: user, channel: channel} do
    assert Service.get(channel.id, user.id, :type) == 0
  end

  test "update", %{user: user, channel: channel, sub: sub} do
    {:ok, subscription} = Service.update(sub, %{type: 1})
    assert subscription.type == 1
    {:ok, subscription} = Service.update(channel.id, user.id, %{type: 2})
    assert subscription.type == 2
  end

end
