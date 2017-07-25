defmodule UccChat.Web.UiChannel.Js do
  import Rebel.Query
  import Rebel.Core

  alias UccChat.Web.ClientView

  require Logger

  def page_loading(socket) do
    insert socket, ClientView.page_loading, prepend: "head"
    socket
  end

  def remove_page_loading(socket) do
    delete socket, "head > style"
    socket
  end

  def start_loading_animation(socket, elem) do
    socket
    |> page_loading
    |> exec_js("$('#{elem}').next().after('#{ClientView.loading_animation}')")
    socket
  end

  def stop_loading_animation(socket) do
    socket
    |> remove_page_loading()
    |> delete(from: ".loading-animation")
    socket
  end
end
