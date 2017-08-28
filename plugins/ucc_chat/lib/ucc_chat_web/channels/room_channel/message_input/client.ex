defmodule UccChatWeb.RoomChannel.MessageInput.Client do

  # import UcxUccWeb.Utils, only: [strip_nl: 1]
  import Rebel.{Query, Core}, warn: false

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

end
