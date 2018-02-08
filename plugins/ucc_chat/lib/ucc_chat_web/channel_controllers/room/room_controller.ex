defmodule UccChatWeb.RoomChannelController do
  use UccChatWeb, :channel_controller

  alias UccChat.{ChannelService, Subscription}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChatWeb.RebelChannel.Client
  # alias UcxUccWeb.Query
  # alias UccChatWeb.ClientView
  alias UccChatWeb.UserChannel.SideNav.Channels

  require Logger

  def show(%{assigns: _assigns} = socket, params) do
    Channels.open_room socket, params["room"], params["room_id"],
      params["display_name"]
    {:noreply, socket}
  end

  def favorite(socket, _param) do
    assigns = socket.assigns
    resp = ChannelService.toggle_favorite(assigns[:user_id],
      assigns[:channel_id])
    {:reply, resp, socket}
  end

  # create a new direct
  def create(%{assigns: assigns} = socket, params) do
    resp = ChannelService.add_direct(params["username"], assigns[:user_id],
      assigns[:channel_id])
    {:reply, resp, socket}
  end

  def hide(%{assigns: assigns} = socket, params) do
    case ChannelService.channel_command(socket, :hide, params["room"],
      assigns[:user_id], assigns[:channel_id]) do
      {:ok, _} ->
        Channels.open_room(socket, params["room"], params["next_room"],
          params["next_room_display_name"])
      {:error, error} ->
        Client.toastr(socket, :error, error)
    end
    {:noreply, socket}
  end

  def leave(%{assigns: assigns} = socket, params) do
    resp = case ChannelService.channel_command(socket, :leave, params["room"],
      assigns[:user_id], nil) do
      {:ok, _} ->
        {:ok, %{}}
      {:error, error} ->
        {:error, %{error: error}}
    end
    {:reply, resp, socket}
  end

  def delete(%{assigns: assigns} = socket, params) do
    resp = ChannelService.delete_channel(socket, params["room"],
      assigns.user_id)
    {:reply, resp, socket}
  end

  def clear_has_unread(%{assigns: assigns} = socket, _params) do
    if assigns[:channel_id] do
      Subscription.set_has_unread(assigns.channel_id, assigns.user_id, false)
    end
    {:noreply, socket}
  end

  def set_has_unread(%{assigns: assigns} = socket, _params) do
    Subscription.set_has_unread(assigns.channel_id, assigns.user_id, true)
    {:noreply, socket}
  end

  @commands ~w(mute-user unmute-user set-moderator unset-moderator set-owner unset-owner remove-user block-user unblock-user)
  @command_list Enum.zip(@commands, ~w(mute unmute set_moderator unset_moderator set_owner unset_owner remove_user block_user unblock_user)a) |> Enum.into(%{})
  @messages [
    nil,
    "User unmuted in Room",
    "User %%user%% is now a moderator of %%room%%",
    "User %%user%% remove from %%room%% moderators",
    "User %%user%% is now an owner of %%room%%",
    "User %%user%% removed from %%room%% owners",
    nil,
    "User is blocked",
    "User is unblocked",
  ]
  @message_list Enum.zip(@commands, @messages) |> Enum.into(%{})

  def command(socket, %{"command" => command, "username" => username})
    when command in @commands do

    Logger.debug fn -> "RoomChannelController: command: #{command}, username: " <>
      "#{inspect username}, socket: #{inspect socket}" end
    user = Helpers.get_user_by_name username

    resp =
      case ChannelService.user_command(socket, @command_list[command],
        user, socket.assigns.user_id, socket.assigns.channel_id) do
        {:ok, _msg} ->
          if message = @message_list[command] do
            message =
              message
              |> String.replace("%%user%%", user.username)
              |> String.replace("%%room%%", socket.assigns.room)
            Phoenix.Channel.push socket, "toastr:success", %{message: message}
          end
          {:ok, %{}}
        {:error, error} ->
          {:error, %{error: error}}
      end
    {:reply, resp, socket}
  end

  @commands ~w(join)
  @command_list Enum.zip(@commands, ~w(join)a) |> Enum.into(%{})

  def command(socket, %{"command" => command, "username" => _username})
    when command in @commands do
    # Logger.warn "RoomChannelController: item: #{inspect @command_list[command]}, command: #{command}, username: #{inspect username}, socket: #{inspect socket}"

    # resp = case ChannelService.user_command(:unmute, user, socket.assigns.user_id, socket.assigns.channel_id) do
    resp = case ChannelService.channel_command(socket, @command_list[command],
      socket.assigns.room, socket.assigns.user_id, socket.assigns.channel_id) do
      {:ok, _msg} ->
        # if message = @message_list[command] do
        #   message = message |> String.replace("%%user%%", user.username) |> String.replace("%%room%%", socket.assigns.room)
        #   Phoenix.Channel.push socket, "toastr:success", %{message: message}
        # end
        {:ok, %{}}
      {:error, error} ->
        {:error, %{error: error}}
    end
    {:reply, resp, socket}
  end

  def command(socket, %{"command" => command, "username" => username}) do
    Logger.debug fn -> "RoomChannelController: command: #{inspect command}, " <>
      "username: #{inspect username}" end
    {:reply, {:ok, %{}}, socket}
  end
end
