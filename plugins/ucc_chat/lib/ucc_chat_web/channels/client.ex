defmodule UccChatWeb.Client do
  use UccChatWeb.RoomChannel.Constants

  import UcxUccWeb.Utils
  import Rebel.{Query, Core}, warn: false

  alias Rebel.Element
  alias UccChatWeb.RebelChannel.Client, as: RebelClient

  require Logger
  # alias Rebel.Element

  @wrapper       ".messages-box .wrapper"
  @wrapper_list  @wrapper <> " > ul"

  # defmacro __using__(_) do
  #   quote do
  #     import UcxUccWeb.Utils
  #     defdelegate send_js(socket, js), to: unquote(__MODULE__)
  #     defdelegate send_js!(socket, js), to: unquote(__MODULE__)
  #     defdelegate closest(socket, selector, class, attr), to: unquote(__MODULE__)
  #     defdelegate append(socket, selector, html), to: unquote(__MODULE__)
  #     defdelegate broadcast!(socket, event, bindings), to: Phoenix.Channel
  #     defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
  #     defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
  #     defdelegate query_one(socket, selector, prop), to: Rebel.Element
  #     defdelegate toastr!(socket, which, message), to: UccChatWeb.RebelChannel.Client
  #     defdelegate toastr(socket, which, message), to: UccChatWeb.RebelChannel.Client
  #   end
  # end

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
  end

  def send_js!(socket, js) do
    exec_js! socket, strip_nl(js)
  end

  # not sure how to do this
  def closest(socket, selector, class, attr) do
    exec_js! socket, """
      var el = document.querySelector('#{selector}');
      console.log('selector', '#{selector}');
      console.log('el', el);
      el = el.closest('#{class}');
      if (el) {
        el.getAttribute('#{attr}');
      } else {
        null;
      }
      """
  end

  def append(socket, selector, html) do
    Rebel.Query.insert socket, html, append: selector
  end

  def close_popup(socket) do
    update socket, :html, set: "", on: ".message-popup-results"
  end

  def get_message_box_value(socket) do
    exec_js! socket, "document.querySelector('#{@message_box}').value;"
  end

  def set_message_box_focus(socket) do
    exec_js socket, set_message_box_focus_js()
  end

  def set_message_box_focus_js,
    do: "var elem = document.querySelector('#{@message_box}'); elem.focus();"

  def clear_message_box(socket) do
    exec_js socket, clear_message_box_js()
  end

  def clear_message_box_js,
    do: set_message_box_focus_js() <> ~s(elem.value = "";)

  def render_popup_results(html, socket) do
    update socket, :html, set: html, on: ".message-popup-results"
  end

  def get_selected_item(socket) do
    case Element.query_one socket, ".popup-item.selected", :dataset do
      {:ok, %{"dataset" => %{"name" => name}}} -> name
      _other -> nil
    end
  end
  def push_message({message, html}, socket) do
    exec_js socket, push_message_js(html, message) <>
      RebelClient.scroll_bottom_js('#{@wrapper}')
  end

  def push_message_js(html, message) do
    encoded = Poison.encode! html
    """
    var node = document.createRange().createContextualFragment(#{encoded});
    var elem = document.querySelector('#{@wrapper_list}');
    elem.append(node);
    Rebel.set_event_handlers('[id="#{message.id}"]');
    UccChat.normalize_message('#{message.id}');
    UccChat.roomManager.updateMentionsMarksOfRoom();
    """
  end

  def broadcast_message({message, html}, socket) do
    js = push_message_js(html, message) <> RebelClient.scroll_bottom_js('#{@wrapper}')
    broadcast_js socket, js
  end

  def broadcast_update_message({message, html}, socket) do
    broadcast_js socket, update_message_js(html, message)
  end

  def update_message_js(html, message) do
    encoded = Poison.encode! html
    """
    $('[id="#{message.id}"]').replaceWith(#{encoded});
    Rebel.set_event_handlers('[id="#{message.id}"]');
    UccChat.normalize_message('#{message.id}');
    UccChat.roomManager.updateMentionsMarksOfRoom();
    """
  end

  def delete_message!(message_id, socket) do
    delete! socket, "li.message#" <> message_id
  end

  defdelegate broadcast!(socket, event, bindings), to: Phoenix.Channel
  defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
  defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
  defdelegate toastr!(socket, which, message), to: UccChatWeb.RebelChannel.Client
  defdelegate toastr(socket, which, message), to: UccChatWeb.RebelChannel.Client
end
