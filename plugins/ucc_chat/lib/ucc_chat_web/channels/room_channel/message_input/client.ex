defmodule UccChatWeb.RoomChannel.MessageInput.Client do

  import UcxUccWeb.Utils
  import Rebel.{Query, Core, Element}, warn: false

  require UccChatWeb.RoomChannel.Constants, as: Const

  def close_popup(socket) do
    update socket, :html, set: "", on: ".message-popup-results"
  end

  def get_message_box_value(socket) do
    exec_js! socket, "document.querySelector('#{Const.message_box}').value;"
  end

  def set_message_box_focus(socket) do
    exec_js socket, set_message_box_focus_js()
  end

  def set_message_box_focus_js,
    do: "var elem = document.querySelector('#{Const.message_box}'); elem.focus();"

  def clear_message_box(socket) do
    exec_js socket, clear_message_box_js()
  end

  def clear_message_box_js,
    do: set_message_box_focus_js() <> ~s(elem.value = "";)

  def render_popup_results(html, socket) do
    update socket, :html, set: html, on: ".message-popup-results"
  end

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
  end

  def get_selected_item(socket) do
    case Element.query_one socket, ".popup-item.selected", :dataset do
      {:ok, %{"dataset" => %{"name" => name}}} -> name
      _other -> nil
    end
  end
end
