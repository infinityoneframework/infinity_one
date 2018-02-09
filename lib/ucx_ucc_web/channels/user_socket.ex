defmodule UcxUccWeb.UserSocket do
  use Phoenix.Socket
  alias UcxUcc.Accounts.User
  alias UcxUcc.Repo
  require UccChat.ChatConstants, as: CC

  use Rebel.Socket, channels: []

  require Logger

  ## Channels
  channel CC.chan_room <> "*", UccChatWeb.RoomChannel    # "ucxchat:"
  channel CC.chan_user <> "*", UccChatWeb.UserChannel  # "user:"
  channel CC.chan_system <> "*", UccChatWeb.SystemChannel  # "system:"
  channel CC.chan_webrtc <> "*", UccWebrtcWeb.WebrtcChannel
  channel CC.chan_client <> "*", MscsWeb.ClientChannel
  channel "landing:*", UcxUccWeb.LandingChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token, "tz_offset" => tz_offset} = payload, socket) do
    # Logger.warn "socket connect params: #{inspect params}, socket: #{inspect socket}"
    case Coherence.verify_user_token(socket, token, &assign/3) do
      {:error, _} -> :error
      {:ok, %{assigns: %{user_id: user_id}} = socket} ->
        case User.user_id_and_username(user_id) |> Repo.one do
          nil ->
            :error
          {user_id, username} ->
            socket =
              socket
              |> assign(:user_id, user_id)
              |> assign(:username, username)
              |> assign(:tz_offset, tz_offset)
            if payload["__rebel_return"] do
              super payload, socket
            else
              {:ok, socket}
            end
        end
    end
  end

  def connect(%{"landing" => "true"} = params, socket) do
    super params, assign(socket, :landing, true)
  end

  def connect(params, socket), do: super(params, socket)


  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     UcxUccWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(%{assigns: %{landing: true}} = socket), do: nil
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"

end
