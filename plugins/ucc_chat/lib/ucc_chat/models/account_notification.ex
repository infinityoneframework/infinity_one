defmodule UccChat.AccountNotification do
  use UccModel, schema: UccChat.Schema.AccountNotification

  def new_changeset(notification_id, account_id) do
    change %{notification_id: notification_id, account_id: account_id}
  end

end
