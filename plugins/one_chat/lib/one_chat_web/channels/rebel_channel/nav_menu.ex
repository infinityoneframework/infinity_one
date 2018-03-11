defmodule OneChatWeb.RebelChannel.NavMenu do
  use OneChatWeb.RebelChannel.Macros

  defjs :open, do: """
    $('.main-content').css('transform', `translateX(260px)`);
    $('.burger').addClass('menu-opened');
    """

  defjs :close, do: """
    $('.main-content').css('transform', `translateX(0px)`)
    $('.burger').removeClass('menu-opened')
    """

end
