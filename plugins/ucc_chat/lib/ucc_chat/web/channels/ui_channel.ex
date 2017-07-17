defmodule UccChat.Web.UiChannel do
  use Rebel.Channel, name: "ui", controllers: [
    UccChat.Web.ChannelController,
  ]
  import Rebel.Core
  import Rebel.Query

  def open_room(socket, sender) do
    IO.inspect sender, label: "**** sender ****"
    socket
  end

  def test(socket, sender) do
    IO.inspect sender, label: "**** sender ****"
    socket
  end
end
