defmodule OneChatWeb.RoomChannel.MessageInput.SlashCommands do
  use OneChatWeb.RoomChannel.Constants

  import InfinityOneWeb.{Utils}

  alias OneChat.SlashCommands, as: Slash
  alias OneChatWeb.MessageView

  require OneChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in("/" <> pattern, context) do
    handle_in pattern, context
  end

  def handle_in(pattern, context) do
    # Logger.warn "Slash commands handle_in"
    pattern
    |> Slash.commands
    |> render_commands(context)
  end

  def handle_select(_buffer, selected, context) when selected in [nil, ""] do
    context.client.close_popup context.socket
    context.client.async_js context.socket, """
      var te = document.querySelector('#{@message_box}');
      te.value = '';
      te.focus();
      """
  end

  def handle_select(_buffer, selected, context) do
    value =
      selected
      |> Slash.special_text
      |> Kernel.<>(" ")
      |> Poison.encode!
    context.client.async_js context.socket, """
      var te = document.querySelector('#{@message_box}');
      te.value = #{value};
      te.focus();
      """
  end

  defp render_commands(commands, context) when commands in [nil, []] do
    context.client.close_popup context.socket
    :close
  end

  defp render_commands(commands, context) do
    MessageView
    |> render_to_string("popup_slash_commands.html",
      chatd: %{open: true, data: commands})
    |> context.client.render_popup_results(context.socket)
  end

  ######################
  # Command handling


end
