defmodule UccChatWeb.RoomChannel.MessageInputTest do
  use UccChatWeb.ChannelCase

  import UccChat.TestHelpers

  alias UccChatWeb.RoomChannel.MessageInput

  defmodule Client do
    def render_popup_results(html, _socket),
      do: send(self(), {:render_popup_results, html})
    def clear_message_box(_), do: send(self(), :clear_message_box)
    def close_popup(_), do: send(self(), :close_popup)
    def send_js(js, _), do: send(self(), {:send_js, js})
    def get_message_box_value(_), do: "test"
    def get_selected_item(_), do: "one"
  end

  setup do
    UccChatWeb.RoomChannel.KeyStore.reset
    insert_roles()
    user = insert_user()
    channel_names = ~w(one two three four five)
    [channel | _] =
      for name <- channel_names, do: insert_channel(user, %{name: name})
    socket =
      %{assigns: %{
        self: self(),
        user_id: user.id,
        channel_id: channel.id,
      }}
    sender =
      %{

      }
    {:ok, socket: socket, sender: sender, user: user, channel: channel}
  end

  test "opens slash commands", %{socket: socket, sender: sender} do
    MessageInput.handle_keydown(socket, sender, "/", Client)
    assert_receive {:render_popup_results, html}
    assert Floki.find(html, ".message-popup-items .popup-item") |> length == 10
  end

  test "opens channels", %{socket: socket, sender: sender} do
    MessageInput.handle_keydown(socket, sender, "#", Client)
    assert_receive {:render_popup_results, html}
    assert Floki.find(html, ".message-popup-items .popup-item") |> length == 5
  end

  test "handles channels", %{socket: socket, sender: sender} do
    MessageInput.handle_keydown(socket, sender, "#", Client)
    MessageInput.handle_keydown(socket, sender, "t", Client)
    assert_receive {:render_popup_results, _}
    assert_receive {:render_popup_results, html}
    assert Floki.find(html, ".message-popup-items .popup-item") |> length == 2
    MessageInput.handle_keydown(socket, sender, "Backspace", Client)
    assert_receive {:render_popup_results, html}
    assert Floki.find(html, ".message-popup-items .popup-item") |> length == 5

    MessageInput.handle_keydown(socket, sender, "o", Client)
    MessageInput.handle_keydown(socket, sender, "n", Client)
    assert_receive {:render_popup_results, _}
    assert_receive {:render_popup_results, html}
    assert Floki.find(html, ".message-popup-items .popup-item") |> length == 1

    data = MessageInput.handle_keydown(socket, sender, "Enter", Client)
    assert_receive :close_popup
    assert data[:buffer] == ""


  end
end
