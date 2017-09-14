defmodule UccChatWeb.RoomChannel.EmojiInput.Client do

  import UcxUccWeb.Utils
  import Rebel.{Query, Core}, warn: false

  # alias Rebel.Element

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
  end
end

