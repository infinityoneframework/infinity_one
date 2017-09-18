defmodule UccChatWeb.RoomChannel.MessageInput.SlashCommands do
  use UccChatWeb.RoomChannel.Constants

  import UcxUccWeb.Utils

  alias UccChat.SlashCommands, as: Slash
  alias UccChatWeb.MessageView

  require UccChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in("/" <> pattern, context) do
    handle_in pattern, context
  end

  def handle_in(pattern, context) do
    Logger.warn "Slash commands handle_in"
    pattern
    |> Slash.commands
    |> render_commands(context)
  end

  def handle_select(buffer, selected, context) do
    if selected != "" do
      context.client.send_js context.socket, """
        var te = document.querySelector('#{@message_box}');
        te.value = '#{Slash.special_text selected} ';
        te.focus();
        """
    end
  end

  defp render_commands([], context) do
    context.client.close_popup context.socket
    :close
  end

  defp render_commands(commands, context) do
    MessageView
    |> render_to_string("popup_slash_commands.html",
      chatd: %{open: true, data: commands})
    |> context.client.render_popup_results(context.socket)
  end
end
