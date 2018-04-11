defmodule OneChatWeb.RoomChannel.MessageInput.Pages do
  use OneChatWeb.RoomChannel.Constants
  import InfinityOneWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import InfinityOneWeb.Gettext

  alias OneChatWeb.MessageView
  alias OneChat.Channel
  alias OneWiki.Page

  require OneChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in("ii" <> pattern, context) do
    handle_in pattern, context
  end

  def handle_in(pattern, context) do
    # Logger.warn "Channels handle_in pattern: #{inspect pattern}"
    "%" <> pattern <> "%"
    |> get_pages(context.user_id)
    |> render_pages(context)
  end

  def handle_select(buffer, selected, context) do
    if selected != "" do
      buffer = Poison.encode!(buffer <> " ")
      context.client.async_js context.socket, """
        var te = document.querySelector('#{@message_box}');
        te.value = #{buffer};
        te.focus();
        """
    end
  end

  defp render_pages([], context) do
    context.client.close_popup context.socket
    :close
  end

  defp render_pages(pages, context) do
    # Logger.error "channels: #{inspect channels}"
    MessageView
    |> render_to_string("popup.html", chatd: %{
        app: "Pages",
        open: true,
        data: pages,
        title: ~g"Pages",
        templ: "popup_pages.html"
    })
    |> context.client.render_popup_results(context.socket)
  end

  defp get_pages(pattern, user_id) do
    get_pages_by_pattern(user_id, pattern)
  end

  defp get_pages_by_pattern(user_id, pattern) do
    user_id
    |> Page.get_pages_by_pattern(pattern, 5)
    |> Enum.map(fn {id, title} -> %{id: id, title: title, username: title} end)
  end

  def add_private(socket, sender) do
    username = exec_js! socket, ~s{$('#{this(sender)}').parent().data('username')}

    socket
    |> OneUiFlexTab.FlexTabChannel.flex_close(sender)
    |> OneChatWeb.UserChannel.SideNav.Directs.open_direct_channel(username)
  end

end
