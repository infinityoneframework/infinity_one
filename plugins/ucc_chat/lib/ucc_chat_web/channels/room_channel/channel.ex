defmodule UccChatWeb.RoomChannel.Channel do
  use UccLogger
  use UccChatWeb.Channel.Utils

  import UcxUccWeb.Gettext

  alias UccChat.{Subscription, Settings, Mute}
  alias UcxUcc.{Accounts, UccPubSub, Permissions}
  alias UccChatWeb.UserChannel
  alias UccChatWeb.RoomChannel.Message, as: WebMessage

  def join(%{} = channel, user_id) do
    case create_subscription channel, user_id do
      {:ok, message} ->
        user = Accounts.get_user user_id
        notify_user_join(channel.id, user)
        {:ok, message}
      error ->
        error
    end
  end

  def add_user(%{} = channel, user_id) do
    case create_subscription channel, user_id do
      {:ok, message} ->
        user = Accounts.get_user user_id
        notify_user_added(channel.id, user)
        {:ok, message}
      error ->
        error
    end
  end

  def leave(%{id: channel_id} = channel, user_id) do
    case delete_subscription channel, user_id do
      {:ok, message} ->
        user = Accounts.get_user user_id
        notify_user_leave(channel_id, user)
        {:ok, message}
      error ->
        error
    end
  end

  def remove_user(%{id: channel_id} = channel, user_id, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "remove-user", channel_id do
      case delete_subscription channel, user_id do
        {:ok, message} ->
          user = Accounts.get_user user_id
          notify_user_removed(channel_id, user)
          {:ok, message}
        error ->
          error
      end
    else
      {:error, permission_error()}
    end
  end

  def remove_user(%{} = channel, user_id, current_user_id) do
    remove_user channel, user_id, Accounts.get_user!(current_user_id)
  end

  def mute_user(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "mute-user", channel_id do
      case Mute.create(%{user_id: user.id, channel_id: channel_id}) do
        {:error, _cs} ->
          message = ~g"User" <> " `@" <> user.username <> "` " <> ~g"already muted."
          {:error, message}
        {:ok, _} ->
          notify_user_muted(channel_id, user, current_user)
          {:ok, ~g"muted"}
      end
    else
      {:error, permission_error()}
    end
  end

  def unmute_user(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "mute-user", channel_id do
      case Mute.get_by user_id: user.id, channel_id: channel_id do
        nil ->
          {:error, ~g"User" <> " `@" <> user.username <> "` " <>
            ~g"is not muted."}
        mute ->
          Mute.delete! mute
          notify_user_unmuted channel_id, user, current_user
          {:ok, ~g"unmuted"}
      end
    else
      {:error, permission_error()}
    end
  end

  def set_owner(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "set-owner", channel_id do
      case Accounts.set_users_role user, "owner", channel_id do
        %{} = user ->
          {:ok, user}
        error ->
          Logger.warn "set_owner error: #{inspect error}"
          {:error, ~g(Problem setting owner)}
      end
    else
      {:error, permission_error()}
    end
  end

  def unset_owner(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "set-owner", channel_id do
      case Accounts.delete_users_role user, "owner", channel_id do
        :ok ->
          {:ok, nil}
        error ->
          Logger.warn "set_owner error: #{inspect error}"
          {:error, ~g(Problem removing owner)}
      end
    else
      {:error, permission_error()}
    end
  end

  def set_moderator(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "set-moderator", channel_id do
      case Accounts.set_users_role user, "moderator", channel_id do
        %{} = user ->
          {:ok, user}
        error ->
          Logger.warn "set_moderator error: #{inspect error}"
          {:error, ~g(Problem setting moderator)}
      end
    else
      {:error, permission_error()}
    end
  end

  def unset_moderator(channel_id, %{} = user, %{} = current_user) do
    current_user = Accounts.preload_schema current_user, [:roles, user_roles: :role]
    if Permissions.has_permission? current_user, "set-moderator", channel_id do
      case Accounts.delete_users_role user, "moderator", channel_id do
        :ok ->
          {:ok, nil}
        error ->
          Logger.warn "set_moderator error: #{inspect error}"
          {:error, ~g(Problem removing moderator)}
      end
    else
      {:error, permission_error()}
    end
  end

  def create_subscription(%{} = channel, user_id) do
    case Subscription.create(%{user_id: user_id, channel_id: channel.id}) do
      {:ok, _} = ok ->
        UccPubSub.broadcast "user:" <> user_id, "new:subscription",
          %{channel_id: channel.id}
        UserChannel.join_room(user_id, channel.name)
        ok
      other ->
        other
    end
  end

  def delete_subscription(channel, user_id) do
    case Subscription.get_by channel_id: channel.id, user_id: user_id do
      nil ->
        {:error, ~g(no subscription)}
      subs ->
        Subscription.delete! subs
        UserChannel.leave_room(user_id, channel.name)
        UccPubSub.broadcast "user:" <> user_id, "delete:subscription",
          %{channel_id: channel.id}
        {:ok, ~g"removed"}
    end
  end

  defp notify_user_join(channel_id, user) do
    unless Settings.hide_user_join do
      WebMessage.broadcast_system_message channel_id, user.id,
        user.username <> ~g( has joined the channel.)
    end
  end

  defp notify_user_added(channel_id, user) do
    unless Settings.hide_user_added do
      WebMessage.broadcast_system_message channel_id, user.id,
        user.username <> ~g( has been added to the channel.)
    end
  end

  defp notify_user_removed(channel_id, user) do
    unless Settings.hide_user_removed do
      WebMessage.broadcast_system_message channel_id, user.id,
        user.username <> ~g( has been removed from the channel.)
    end
  end

  defp notify_user_leave(channel_id, user) do
    unless Settings.hide_user_leave() do
      WebMessage.broadcast_system_message channel_id, user.id,
        user.username <> ~g( has left the channel.)
    end
  end

  defp notify_user_muted(channel_id, user, current_user) do
    unless UccSettings.hide_user_muted() do
      message = ~g(User ) <> user.username <> ~g( muted by ) <> current_user.username
      WebMessage.broadcast_system_message(channel_id, current_user.id, message)
    end
  end

  defp notify_user_unmuted(channel_id, user, current_user) do
    unless UccSettings.hide_user_muted() do
      message = ~g(User ) <> user.username <> ~g( unmuted by ) <> current_user.username
      WebMessage.broadcast_system_message(channel_id, current_user.id, message)
    end
  end

  defp permission_error, do: ~g(You don't have Permission for that action)

end
