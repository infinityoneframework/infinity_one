defmodule UccChat.AccountNotificationTest do
  use UccChat.DataCase

  alias UccChat.AccountNotification
  alias UccChat.TestHelpers, as: H

  setup do
    H.insert_roles()
    user = H.insert_user
    account = H.insert_account user
    channel = H.insert_channel user
    {:ok, user: user, channel: channel, account: account,
      notification: H.insert_notification(channel)}
  end

  test "create", %{account: account, notification: notification} do
    {:ok, an} = AccountNotification.create %{
      account_id: account.id, notification_id: notification.id}
    assert an.account_id == account.id
    assert an.notification_id == notification.id
  end

  test "create!", %{account: account, notification: notification} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    assert an.account_id == account.id
    assert an.notification_id == notification.id
  end

  test "get", %{account: account, notification: notification} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    assert H.schema_eq(AccountNotification.get(an.id), an)
  end

  test "get preload", %{account: account, notification: notification} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    an1 = AccountNotification.get(an.id, preload: [:account, :notification])
    assert an1.id == an.id
    assert an1.account.id == account.id
    assert an1.notification.id == notification.id
  end

  test "get!", %{account: account, notification: notification} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    assert H.schema_eq(AccountNotification.get!(an.id), an)
  end

  test "get_by", %{account: account, notification: notification} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    assert H.schema_eq(AccountNotification.get_by(account_id: account.id,
      notification_id: notification.id), an)
  end

  test "get_by preload", %{account: account, notification: notification,
   user: user, channel: channel} do
    an = AccountNotification.create! %{
      account_id: account.id, notification_id: notification.id}
    an1 = AccountNotification.get_by(account_id: account.id,
      notification_id: notification.id, preload: [account: :user, notification: :channel])
    assert an1.id == an.id
    assert an1.account.id == account.id
    assert an1.account.user.id == user.id
    assert an1.notification.id == notification.id
    assert an1.notification.channel.id == channel.id
  end

end
