defmodule UccChatWeb.RebelChannel.RoomHistoryManager do
  @wrapper "'.messages-box .wrapper'"
  @this    "UccChat.roomHistoryManager"

  @cache_room_js """
    if (ucxchat.channel_id) {
      #{@this}.cached_scrollTop = $(#{@wrapper})[0].scrollTop;
    }
    """
  use UccChatWeb.RebelChannel.Macros

  defjs :cache_room, do: @cache_room_js

  defjs :cache_room_content,
    do: @cache_room_js <>
      " $('.main-content-cache').html($('.main-content').html());"

  defjs :restore_cached_room_js, do: """
    if (ucxchat.channel_id) {
      $(#{@wrapper})[0].scrollTop = #{@this}.cached_scrollTop;
      UccChat.roomManager.bind_history_manager_scroll_event();
    }
    """

  defjs :close_js, do: """
    $('.main-content').css('transform', `translateX(0px)`)
    $('.burger').removeClass('menu-opened')
    """

  # def cache_room(socket) do
  #   do_exec_js socket, cache_room_js()
  #   socket
  # end

  # def cache_room_content(socket) do
  #   do_exec_js socket, cache_room_content_js()
  #   socket
  # end

  # def cache_room_content_js do
  #   cache_room_js() <> " $('.main-content-cache').html($('.main-content').html());"
  # end

  # def cache_room_js do
  #   """
  #   if (ucxchat.channel_id) {
  #     #{this()}.cached_scrollTop = $(#{@wrapper})[0].scrollTop;
  #   }
  #   """
  #   |> String.replace("\n", "")
  # end

  # def restore_cached_room_js do
  #   """
  #   if (ucxchat.channel_id) {
  #     $(#{@wrapper})[0].scrollTop = #{this()}.cached_scrollTop;
  #     UccChat.roomManager.bind_history_manager_scroll_event();
  #   }
  #   """
  #   |> String.replace("\n", "")
  # end

  # def this do
  #   "UccChat.roomHistoryManager"
  # end

  # def close_js do
  #   """
  #   $('.main-content').css('transform', `translateX(0px)`)
  #   $('.burger').removeClass('menu-opened')
  #   """
  #   |> String.replace("\n", "")
  # end
end
