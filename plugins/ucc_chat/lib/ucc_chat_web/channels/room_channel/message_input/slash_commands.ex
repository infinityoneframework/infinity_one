defmodule UccChatWeb.RoomChannel.MessageInput.SlashCommands do

  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false

  alias UccChat.SlashCommands, as: Slash
  # alias UccChatWeb.UserChannel.MessageInput
  alias UccChatWeb.MessageView

  require UccChatWeb.RoomChannel.Constants, as: Const
  require Logger

  def new(mb_data, _key, info) do
    Logger.warn "Slash commands new mb_data: #{inspect mb_data}"
    ""
    |> Slash.commands
    |> render_commands(mb_data, info.socket)

    Map.put mb_data, :app, SlashCommands
  end

  def handle_in(mb_data, _key, info) do
    Logger.warn "Slash commands handle_in mb_data: #{inspect mb_data}"
    mb_data.keys
    |> Slash.commands
    |> render_commands(mb_data, info.socket)
  end

  def handle_select(mb_data, selected, info) do
    exec_js info.socket, """
      var te = document.querySelector('#{Const.message_box}');
      te.value = '#{Slash.special_text selected}';
      te.focus();
      """ |> strip_nl
    mb_data
  end

  defp render_commands(nil, mb_data, _socket), do: mb_data
  defp render_commands(commands, mb_data, socket) do
    html = render_to_string MessageView,
      "popup_slash_commands.html",
      chatd: %{open: true, data: commands}

    update socket, :html, set: html, on: ".message-popup-results"

    mb_data
  end

end

  # def handle_in("get:slashcommands" <> _mod, msg) do
  #   Logger.debug "get:slashcommands, msg: #{inspect msg}"
  #   pattern = msg["pattern"] |> to_string

  #   if commands = SlashCommands.commands(pattern) do
  #     chatd = %{open: true, data: commands}

  #     html =
  #       "popup_slash_commands.html"
  #       |> MessageView.render(chatd: chatd)
  #       |> Helpers.safe_to_string

  #     {:ok, %{html: html}}
  #   else
  #     {:ok, %{close: true}}
  #   end
  # end
