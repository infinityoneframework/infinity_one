defmodule UccChatWeb.RoomChannel.Constants do
  use Constants

  define item,           ".popup-item"
  define selected,       item() <> ".selected"
  define message_box,    "textarea.message-form-text"

end
