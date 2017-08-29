defmodule UccChatWeb.RoomChannel.MessageInput.SlashCommands do

  import UcxUccWeb.Utils

  alias UccChat.SlashCommands, as: Slash
  alias UccChatWeb.MessageView

  require UccChatWeb.RoomChannel.Constants, as: Const
  require Logger

  def new(mb_data, _key, info) do
    Logger.warn "Slash commands new mb_data: #{inspect mb_data}"
    ""
    |> Slash.commands
    |> render_commands(mb_data, info.socket, info)

    Map.put mb_data, :app, SlashCommands
  end

  def handle_in(mb_data, _key, info) do
    Logger.warn "Slash commands handle_in mb_data: #{inspect mb_data}"
    mb_data
    |> buffer
    |> Slash.commands
    |> render_commands(mb_data, info.socket, info)
  end

  defp buffer(%{buffer: "/" <> buffer}), do: buffer

  def handle_select(mb_data, selected, info) do
    info.client.send_js info.socket, """
      var te = document.querySelector('#{Const.message_box}');
      te.value = '#{Slash.special_text selected} ';
      te.focus();
      """
    mb_data
  end

  defp render_commands(nil, mb_data, _socket, _info), do: mb_data
  defp render_commands(commands, mb_data, socket, info) do
    MessageView
    |> render_to_string("popup_slash_commands.html",
      chatd: %{open: true, data: commands})
    |> info.client.render_popup_results(socket)

    mb_data
  end

end
