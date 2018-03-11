defmodule OneChatWeb.RoomChannel.MessageInput.Channels do
  use OneChatWeb.RoomChannel.Constants

  import InfinityOneWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import InfinityOneWeb.Gettext

  alias OneChatWeb.MessageView
  alias OneChat.Channel

  require OneChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in("#" <> pattern, context) do
    handle_in pattern, context
  end

  def handle_in(pattern, context) do
    # Logger.warn "Channels handle_in pattern: #{inspect pattern}"
    "%" <> pattern <> "%"
    |> get_channels(context.user_id)
    |> render_channels(context)
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

  defp render_channels([], context) do
    context.client.close_popup context.socket
    :close
  end

  defp render_channels(channels, context) do
    # Logger.error "channels: #{inspect channels}"
    MessageView
    |> render_to_string("popup.html", chatd: %{
        app: "Channels",
        open: true,
        data: channels,
        title: ~g"Channels",
        templ: "popup_channel.html"
    })
    |> context.client.render_popup_results(context.socket)
  end

  defp get_channels(pattern, user_id) do
    get_channels_by_pattern(user_id, pattern)
  end

  defp get_channels_by_pattern(user_id, pattern) do
    user_id
    |> Channel.get_channels_by_pattern(pattern, 5)
    |> Enum.map(fn {id, name} -> %{id: id, name: name, username: name} end)
  end

  def add_private(socket, sender) do
    username = exec_js! socket, ~s{$('#{this(sender)}').parent().data('username')}

    socket
    |> OneUiFlexTab.FlexTabChannel.flex_close(sender)
    |> OneChatWeb.UserChannel.SideNav.Directs.open_direct_channel(username)
  end

end
