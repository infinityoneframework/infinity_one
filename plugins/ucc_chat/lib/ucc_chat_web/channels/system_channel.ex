defmodule UccChatWeb.SystemChannel do
  use Phoenix.Channel
  use UccLogger

  alias UcxUccWeb.Presence
  alias UccChatWeb.UserChannel
  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUcc.{UccPubSub, Accounts}

  # import Ecto.Query

  @blur_timer 3 * 60 * 1000
  # @blur_timer 10 * 1000

  # import Ecto.Query

  # alias Phoenix.Socket.Broadcast
  # alias UccChat.{Subscription, Repo, Flex, FlexBarService, ChannelService}
  # alias UccChat.{AccountView, Account, AdminService}
  # alias UccChat.ServiceHelpers, as: Helpers
  require UccChat.ChatConstants, as: CC

  intercept ["presence_diff"]

  def join(CC.chan_system(), _params, socket) do
    send(self(), :after_join)

    :ok = UccChat.ChannelMonitor.monitor(:chan_system, self(),
      {__MODULE__, :leave, [socket.assigns.user_id]})

    {:ok, socket}
  end

  def leave(pid, user_id) do
    user = Accounts.get_user user_id
    if user.status in [nil, ""] do
      UccChat.PresenceAgent.unload(user_id)
    end
    UcxUccWeb.Presence.untrack(pid, CC.chan_system(), user_id)
    UccPubSub.broadcast("user:" <> user_id, "user:leave")
  end

  def handle_out(ev = "presence_diff", params, socket) do
    trace(ev, params)
    push socket, ev, params
    {:noreply, socket}
  end

  ###############
  # handle_in

  def handle_in(ev = "state:blur", params, socket) do
    trace ev, params
    # TODO: move this blur timer to a configuration item
    ref = Process.send_after self(), :blur_timeout, @blur_timer
    UserChannel.user_state(socket.assigns.user_id, "blur")
    {:noreply, assign(socket, :blur_ref, ref)}
  end
  def handle_in(ev = "state:focus", params, socket) do
    trace ev, params
    # TODO: move this blur timer to a configuration item
    socket =
      case socket.assigns[:blur_ref] do
        nil ->
          # Logger.warn "focus socket: #{inspect socket}"
          update_status socket, "online"
          socket
        ref ->
          Process.cancel_timer ref
          assign(socket, :blur_ref, nil)
      end
      UserChannel.user_state(socket.assigns.user_id, "active")
    {:noreply, socket}
  end

  # default unknown handler
  def handle_in(event, params, socket) do
    Logger.error "SystemChannel.handle_in unknown event: #{inspect event}, " <>
      "params: #{inspect params}, assigns: #{inspect socket.assigns}"
    {:noreply, socket}
  end

  ###############
  # Info messages

  def handle_info(:blur_timeout, socket) do
    # Logger.warn "blur_timeout, socket: #{inspect socket}"
    update_status socket, "away"
    UserChannel.user_state(socket.assigns.user_id, "idle")
    {:noreply, assign(socket, :blur_ref, nil)}
  end

  def handle_info(:after_join, socket) do
    list = Presence.list(socket)

    push socket, "presence_state", list
    user_id = socket.assigns.user_id
    user = Helpers.get_user!(user_id)
    status =
      if user.chat_status in [nil, ""], do: "online", else: user.chat_status
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      status: status,
      username: user.username
    })
    update_status socket, status
    UccPubSub.subscribe "status:" <> user_id
    {:noreply, socket}
  end

  def handle_info({"status:" <> _, "set:" <> status, _payload}, socket) do
    if status != "" do
      UccChat.PresenceAgent.put(socket.assigns.user_id, status)
      update_status socket, status
    end
    {:noreply, socket}
  end

  def update_status(%{assigns: %{user_id: user_id, username: username}} =
    socket, status) do
    case UccChat.PresenceAgent.get_and_update_presence(user_id, status) do
      ^status ->
        Presence.update socket, user_id,
          %{status: status, username: username}
      _ ->
        nil
    end
  end

  def terminate(_, socket) do
    assigns = socket.assigns
    user = Accounts.get_user assigns.user_id
    if user.chat_status in [nil, ""] do
      Presence.update socket, assigns.user_id,
        %{status: "offline", username: assigns.username}
    end
  end
end
