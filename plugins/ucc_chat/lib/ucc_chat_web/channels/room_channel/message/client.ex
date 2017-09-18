defmodule UccChatWeb.RoomChannel.Message.Client do
  # use UccChatWeb, :channel
  use UccChatWeb.Client
  use UccLogger

  import Rebel.{Query, Core}, warn: false
  import UcxUccWeb.Utils, only: [strip_nl: 1]

  alias UccChatWeb.RebelChannel.Client, as: RebelClient

  @wrapper       ".messages-box .wrapper"
  @wrapper_list  @wrapper <> " > ul"

  def push_message({message, html}, socket) do
    exec_js message, push_message_js(html, message)
    RebelClient.scroll_bottom(socket, '#{@wrapper}')
  end

  def push_message_js(html, message) do
    encoded = Poison.encode! html |> strip_nl()
    """
    var node = document.createRange().createContextualFragment(#{encoded});
    var elem = document.querySelector('#{@wrapper_list}');
    elem.append(node);
    Rebel.set_event_handlers('[id="#{message.id}"]');
    UccChat.normalize_message('#{message.id}');
    """ |> strip_nl()
  end

  def broadcast_message({message, html}, socket) do
    js = push_message_js(html, message) <> RebelClient.scroll_bottom_js('#{@wrapper}')
    broadcast_js socket, js
  end

  def broadcast_update_message({message, html}, socket) do
    broadcast_js socket, update_message_js(html, message)
  end

  def update_message_js(html, message) do
    encoded = Poison.encode! html |> strip_nl()
    """
    $('#' + '#{message.id}').replaceWith(#{encoded});
    Rebel.set_event_handlers('[id="#{message.id}"]');
    UccChat.normalize_message('#{message.id}');
    """ |> strip_nl()
  end

  def delete_message!(message_id, socket) do
    delete! socket, "li.message#" <> message_id
  end

end
