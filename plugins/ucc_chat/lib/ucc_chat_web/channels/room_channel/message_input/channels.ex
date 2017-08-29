defmodule UccChatWeb.RoomChannel.MessageInput.Channels do
  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import UcxUccWeb.Gettext

  alias UccChatWeb.MessageView
  alias UccChat.Channel

  require UccChatWeb.RoomChannel.Constants, as: Const
  require Logger

  def new(mb_data, _key, info) do
    # Logger.warn "new mb_data: #{inspect mb_data}"
    "%"
    |> get_channels(info.user_id)
    |> render_channels(mb_data, info.socket, info)

    Map.put mb_data, :app, Channels
  end

  def handle_in(mb_data, _key, info) do
    # Logger.warn "Slash commands handle_in mb_data: #{inspect mb_data}"
    "%" <> buffer(mb_data) <> "%"
    |> get_channels(info.user_id)
    |> render_channels(mb_data, info.socket, info)
  end

  defp buffer(%{keys: "#" <> keys}), do: keys

  def handle_select(mb_data, selected, info) do
    if selected != "" do
      info.client.send_js info.socket, """
        var te = document.querySelector('#{Const.message_box}');
        te.value = '##{selected} ';
        te.focus();
        """
    end
    mb_data
  end

  defp render_channels(nil, mb_data, _socket, _info), do: mb_data
  defp render_channels(channels, mb_data, socket, info) do
    MessageView
    |> render_to_string("popup.html", chatd: %{
        open: true,
        data: channels,
        title: ~g"Channels",
        templ: "popup_channel.html"
    })
    |> info.client.render_popup_results(socket)
    mb_data
  end

  defp get_channels(pattern, user_id) do
    get_channels_by_pattern(user_id, pattern)
  end

  defp get_channels_by_pattern(user_id, pattern) do
    user_id
    |> Channel.get_channels_by_pattern(pattern, 5)
    |> Enum.map(fn {id, name} -> %{id: id, name: name, username: name} end)
  end

end
