defmodule UccChatWeb.RebelChannel.NavMenu do
  use UccChatWeb.RebelChannel.Macros

  defjs :open, do: """
    $('.main-content').css('transform', `translateX(260px)`);
    $('.burger').addClass('menu-opened');
    """

  defjs :close, do: """
    $('.main-content').css('transform', `translateX(0px)`)
    $('.burger').removeClass('menu-opened')
    """

end
