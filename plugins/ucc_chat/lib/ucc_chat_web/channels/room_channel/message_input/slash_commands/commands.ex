defmodule UccChatWeb.RoomChannel.MessageInput.SlashCommands.Commands do
  use UccChatWeb.RoomChannel.Constants

  import UcxUccWeb.{Utils, Gettext}

  alias UccChat.SlashCommands, as: Slash
  alias UccChat.{ChannelService, Channel, Subscription}
  alias UccChatWeb.MessageView
  alias UccChatWeb.Client
  alias UcxUcc.Accounts
  alias UccChat.NotifierService, as: Notifier

  require UccChat.ChatConstants, as: CC
  require UccChatWeb.RoomChannel.MessageInput
  require Logger

  def run(buffer, sender, socket, client \\ Client)

  def run("/" <> buffer, sender, socket, client) do
    Logger.info "Command #{buffer}, sender: #{inspect sender}"
    [command | args] = String.split buffer, " ", trim: true
    run_command(command, args, sender, socket, client)
    client.clear_message_box socket
    false
  end

  def run(_buffer, _sender, _socket, _client) do
    true
  end

  def run_command(command, args, sender, socket, client \\ Client)

  def run_command("join", args, sender, socket, client) do
    if name = get_channel_name(args, client) do
      assigns = socket.assigns
      case ChannelService.channel_command socket, :join, name, assigns.user_id,
        assigns.channel_id do

        {:ok, message} ->
          client.toastr! socket, :success, message
        {:error, message} ->
          client.toastr! socket, :error, message
      end
    end
  end

  def run_command("leave", [], sender, socket, client) do
    assigns = socket.assigns
    with channel when not is_nil(channel) <- Channel.get(assigns.channel_id),
         {:ok, message} <- ChannelService.channel_command(socket, :leave, channel,
          assigns.user_id, assigns.channel_id) do
      client.toastr! socket, :success, message
    else
      {:error, message} -> client.toastr! socket, :error, message
      _ -> client.toastr! :error, ~g(Sorry, could not do that!)
    end
  end

  def run_command("leave", args, sender, socket, client) do
    invalid_args_error args, client
  end

  def run_command("create", args, sender, socket, client) do
    assigns = socket.assigns
    name = get_channel_name(args, client)
    with name when not is_nil(name) <- name,
         nil <- Channel.get_by(name: name),
         {:ok, message} <- ChannelService.channel_command(socket, :create,
            name, assigns.user_id, assigns.channel_id) do

      client.toastr! socket, :success, message
    else
      {:error, message} ->
        client.toastr! socket, :error, message
      _ ->
        client.toastr! socket, :error, no_room_message()
    end
  end

  def run_command("open", args, sender, socket, client) do
    if name = get_channel_name args, client do
      if Channel.get_by(name: name) do
        Phoenix.Channel.push socket, "room:open", %{room: name}
      else
        client.toastr! socket, :error, no_room_message()
      end
    end
  end

  def run_command("archive", [], sender, socket, client) do
    assigns = socket.assigns
    if channel = Channel.get assigns.channel_id do
      archive_channel(channel, sender, socket, client)
    else
      client.toastr! socket, :error, sorry_message()
    end
  end

  def run_command("archive", args, sender, socket, client) do
    if name = get_channel_name args, client do
      if channel = Channel.get_by name: name do
        archive_channel(channel, sender, socket, client)
      else
        client.toastr! socket, :error, no_room_message()
      end
    end
  end

  def run_command("unarchive", [], sender, socket, client) do
    client.toastr! socket, :error, ~g(The unarchive command requires a room name)
  end

  def run_command("unarchive", args, sender, socket, client) do
    if name = get_channel_name args, client do
      assigns = socket.assigns
      if channel = Channel.get_by name: name do
        unarchive_channel(channel, sender, socket, client)
      else
        client.toastr! socket, :error, no_room_message()
      end
    end
  end

  # Default catch all
  def run_command(unsupported, _args, sender, socket, _client) do
    Logger.error "Unsupported command #{unsupported}, sender: #{inspect sender}"
    socket
  end

  defp get_channel_name([name], _client) do
    String.trim_leading name, "#"
  end
  defp get_channel_name(args, client) do
    invalid_args_error args, client
    nil
  end

  defp invalid_args_error(args, client) do
    client.toastr! :error, ~g(Invalid argument!) <> " " <> Enum.join(args, " ")
  end

  defp no_room_message, do: ~g(No room by that name)
  defp sorry_message, do: ~g(Sorry, something went wrong.)

  defp archive_channel(%{archived: true} = channel, sender, socket, client) do
    client.toastr! socket, :error, ~g(Room is already archived.)
  end

  defp archive_channel(%{id: id} = channel, sender, socket, client) do
    user = Accounts.get_user socket.assigns.user_id, preload: [:roles]
    case Channel.update channel, %{archived: true} do
      {:ok, _} ->
        Subscription.update_all_hidden(id, true)
        Notifier.notify_action(socket, :archive, channel, user)
        socket.endpoint.broadcast! CC.chan_room <> channel.name, "room:state_change", %{change: "archive", channel_id: id}
        socket.endpoint.broadcast! CC.chan_room <> channel.name, "room:update:list", %{}
      {:error, changeset} ->
        Logger.warn "error archiving channel #{inspect changeset.errors}"
        client.toastr! socket, :error, ~g(Problem archiving channel)
    end
  end

  defp unarchive_channel(%{archived: false} = channel, sender, socket, client) do
    client.toastr! socket, :error, ~g(Room is not archived.)
  end

  defp unarchive_channel(%{id: id} = channel, sender, socket, client) do
    user = Accounts.get_user socket.assigns.user_id, preload: [:roles]
    case Channel.update channel, %{archived: false} do
      {:ok, _} ->
        Subscription.update_all_hidden(id, false)
        Notifier.notify_action(socket, :unarchive, channel, user)
        socket.endpoint.broadcast! CC.chan_room <> channel.name, "room:state_change", %{change: "unarchive", channel_id: id}
        socket.endpoint.broadcast! CC.chan_room <> channel.name, "room:update:list", %{}
      {:error, changeset} ->
        Logger.warn "error unarchiving channel #{inspect changeset.errors}"
        client.toastr! socket, :error, ~g(Problem unarchiving channel)
    end
  end

end
