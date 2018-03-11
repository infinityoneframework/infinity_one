defmodule OneChatWeb.RebelChannel.SideNav do
  use OneChatWeb.RebelChannel.Macros

  defjs :open do
    alias OneChatWeb.RebelChannel.{RoomHistoryManager, NavMenu}, warn: false
    """
    #{RoomHistoryManager.cache_room_content_js()};
    #{NavMenu.open_js()};
    $('div.flex-nav').removeClass('animated-hidden');
    OneChat.sideNav.set_nav_top_icon('close');
    """
  end

  # defjs :set_nav_top_icon, [:icon] do

  # end

  def this do
    "OneChat.sideName"
  end
end
