defmodule UccChatWeb.RoomChannel.Message.Client do
  # use UccChatWeb, :channel
  use UccLogger

  import Rebel.{Query, Core}, warn: false
  import UcxUccWeb.Utils, only: [strip_nl: 1]

  alias UccChatWeb.RebelChannel.Client, as: RebelClient

  # require UccChat.ChatConstants, as: CC

  @wrapper       ".messages-box .wrapper"
  @wrapper_list  @wrapper <> " > ul"

  def push_message(message, socket) do
    exec_js message, push_message_js(message)
    RebelClient.scroll_bottom(socket, '#{@wrapper}')
  end

  def push_message_js(message) do
    message = Poison.encode! message |> strip_nl()
    """
    var node = document.createRange().createContextualFragment(#{message});
    var elem = document.querySelector('#{@wrapper_list}');
    elem.append(node);
    """ |> strip_nl()
  end

  def broadcast_message(message, socket) do
    js = push_message_js(message) <> RebelClient.scroll_bottom_js('#{@wrapper}')
    broadcast_js socket, js
    # socket.endpoint.broadcast CC.chan_room <> socket.assigns.room, "send:message", %{js: js}
  end
end
