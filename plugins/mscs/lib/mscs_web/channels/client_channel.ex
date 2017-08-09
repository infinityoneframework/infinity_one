defmodule MscsWeb.ClientChannel do
  use UccLogger
  use UccChatWeb, :channel
  use UcxUcc
  use Rebel.Channel, name: "client", controllers: [
    UccChatWeb.ChannelController
  ], intercepts: [
  ]

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import Rebel.Browser, warn: false

  require UccChat.ChatConstants, as: CC

  onconnect :on_connect

  def on_connect(socket) do
    Logger.error "on_connect"
    socket
  end

  def topic(_broadcasting, _controller, _request_path, conn_assigns) do
    topic = conn_assigns[:current_user] |> Map.get(:id)
    Logger.warn "ClientChannel topic call: #{topic}"
    topic
  end

  def join(CC.chan_client() <> user_id = event, payload, socket) do
    Logger.error "user_id: #{user_id}"
    trace(event, payload)
    # send(self(), {:after_join, payload})
    super event, payload, socket
  end

  def join(ev, msg, socket) do
    Logger.error "ev: #{ev}"
    trace ev, msg
    # send self(), {:after_join, room, msg}
    super ev, msg, socket
  end

  def click_shift(socket, sender) do
    update socket, :class, toggle: "flipped", on: "#keys-pad"
  end

  def click_volume_up(socket, sender) do
    trace "", sender
    socket
  end

  def click_volume_down(socket, sender) do
    trace "", sender
    socket
  end
  def click_mute(socket, sender) do
    trace "", sender
    socket
  end
  def click_release(socket, sender) do
    trace "", sender
    socket
  end
  def click_handsfree(socket, sender) do
    trace "", sender
    socket
  end
  def click_headset(socket, sender) do
    trace "", sender
    socket
  end
  def click_hold(socket, sender) do
    trace "", sender
    socket
  end
  def click_dialpad(socket, sender) do
    trace "", sender
    socket
  end

  def click_func_cancel(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_cursor_up(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_cursor_left(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_cursor_enter(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_cursor_right(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_cursor_bottom(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_settings(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_favorites(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_services(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_voice_message(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_portal(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_portal(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_history(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_record(socket, sender) do
    trace "", sender
    socket
  end
  def click_func_directory(socket, sender) do
    trace "", sender
    socket
  end
  def click_program_key(socket, sender) do
    trace "", sender
    socket
  end
  def click_softkey(socket, sender) do
    trace "", sender
    socket
  end
end

