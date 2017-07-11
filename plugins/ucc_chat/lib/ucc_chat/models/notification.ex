defmodule UccChat.Notification do
  use UccModel, schema: UccChat.Schema.Notification

  alias UccChat.Schema.{AccountNotification, NotificationSetting}

  def new_changeset(channel_id) do
    settings = Map.from_struct %NotificationSetting{}
    change %{channel_id: channel_id, settings: settings}
  end

  def get_notification(%{id: id}, channel_id), do: get_notification(id, channel_id)
  def get_notification(id, channel_id) do
    from n in @schema,
      join: j in AccountNotification,
      on: j.notification_id == n.id,
      where: j.account_id == ^id and n.channel_id == ^channel_id,
      select: n
  end
  # def get_notification_by_user_id(user_id, channel_id) do
  #   from a in Account,
  #     join: u in User, on: u.id == ^user_id,
  #     join: j in AccountNotification, on: j.account_id == a.id,
  #     join: n in @mod, on: n.id == j.notification_id,

  #     select: a
  #   # from u in User,
  #   #   join: a in Account, on: a.user_id == u.id,
  #   #   join: j in AccountNotification, on: j.account_id == a.id,
  #   #   join: n in @mod, on: n.id == j.notification_id,
  #   #   # where: n.channel_id == ^channel_id,
  #   #   select: a
  #   #   # select: n
  # end

end
