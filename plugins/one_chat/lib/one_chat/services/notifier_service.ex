defmodule OneChat.NotifierService do
  # use OneChat.Shared, :service
  # use InfinityOneWeb.Gettext

  # require Logger

  # alias OneChat.{MessageService}

  def notify_action(_socket, _action, _channel, _user) do
    raise "The notify_action function is not supported"
    # do_notifier_action(socket, action, user, channel)
  end

  # defp do_notifier_action(_socket, :archive, _owner, _channel) do
  #   raise "not supported"
  #   # body = ~g"This room has been archived by " <> owner.username
  #   # MessageService.broadcast_system_message(channel.id, owner.id, body)
  # end

  # defp do_notifier_action(_socket, :unarchive, _owner, _channel) do
  #   raise "not supported"
  #   # body = ~g"This room has been unarchived by " <> owner.username
  #   # MessageService.broadcast_system_message(channel.id, owner.id, body)
  # end

  # defp do_notifier_action(_socket, _action, _owner, _channel) do
  #   raise "not supported"
  #   # Logger.warn "unsupported action: #{inspect action}, channel.id: " <>
  #   #   "#{inspect channel.id}, channel.name: #{inspect channel.name}"
  # end

end
