defmodule UccChatWeb.RoomChannel.MessageInput.Client do

  use UccChatWeb.Client
  use UccChatWeb.RoomChannel.Constants

  import Rebel.{Query, Core}, warn: false

  alias Rebel.Element

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

end
