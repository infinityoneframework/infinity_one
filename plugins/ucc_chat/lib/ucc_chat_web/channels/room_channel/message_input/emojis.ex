defmodule UccChatWeb.RoomChannel.MessageInput.Emojis do
  use UccChatWeb.RoomChannel.Constants

  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import UcxUccWeb.Gettext

  alias UccChatWeb.MessageView
  alias UccChat.Emoji

  require UccChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in(":" <> pattern, context) do
    handle_in pattern, context
  end

  def handle_in(pattern, context) do
    Logger.info "pattern: #{inspect pattern}"
    pattern
    |> get_emojis
    |> render_emojis(context)
  end

  def handle_select(buffer, selected, context) do
    if selected != "" do
      buffer = Regex.replace ~r/:(:[^\s]*:)/, buffer, "\\1"
      context.client.send_js context.socket, """
        var te = document.querySelector('#{@message_box}');
        te.value = '#{buffer} ';
        te.focus();
        """
    end
  end

  defp render_emojis([], context) do
    context.client.close_popup context.socket
    :close
  end

  defp render_emojis(emojis, context) do
    MessageView
    |> render_to_string("popup_emoji.html", chatd: %{
        open: true,
        data: emojis,
        title: ~g(Emoji),
        templ: "popup_emoji.html"
      })
    |> context.client.render_popup_results(context.socket)
  end

  defp get_emojis(pattern) do
    Emoji.commands pattern
  end

end
