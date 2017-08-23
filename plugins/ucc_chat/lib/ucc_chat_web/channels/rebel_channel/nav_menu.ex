defmodule UccChatWeb.RebelChannel.NavMenu do
  import Rebel.Query
  import Rebel.Core
  import UccChatWeb.RebelChannel.Client


  def open(socket) do
    do_exec_js socket, open_js()
    socket
  end

  def close(socket) do
    do_exec_js socket, close_js()
    socket
  end

  def open_js do
    """
    $('.main-content').css('transform', `translateX(260px)`);
    $('.burger').addClass('menu-opened');
    """
    |> String.replace("\n", "")
  end

  def close_js do
    """
    $('.main-content').css('transform', `translateX(0px)`)
    $('.burger').removeClass('menu-opened')
    """
    |> String.replace("\n", "")
  end
end
