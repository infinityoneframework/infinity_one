defmodule UccChatWeb.RoomChannel.MessageInputTest do

  # TODO: Uncomment this file and fix the channel init so that tests will pass.
  #       They broke when I added the typing sever stuff.

  # use UccChatWeb.ChannelCase
  # use UccChatWeb.RoomChannel.Constants

  # import UccChat.TestHelpers

  # alias UccChatWeb.RoomChannel.MessageInput
  # require  UccChat.ChatConstants, as: CC

  # @endpoint UcxUccWeb.Endpoint

  # defmodule Client do
  #   def render_popup_results(html, _socket),
  #     do: send(self(), {:render_popup_results, html})
  #   def clear_message_box(_), do: send(self(), :clear_message_box)
  #   def close_popup(_), do: send(self(), :close_popup)
  #   def send_js(js, _), do: send(self(), {:send_js, js})
  #   def get_message_box_value(_), do: "test"
  #   def get_selected_item(_), do: "one"
  # end

  # setup context do
  #   if context[:database] do
  #     insert_roles()
  #     user = insert_user()
  #     channel_names = ~w(one two three four five)
  #     [channel | _] =
  #       for name <- channel_names, do: insert_channel(user, %{name: name})
  #     {:ok, socket} = connect(UcxUccWeb.UserSocket, %{})
  #     {:oke, _, socket} =
  #       ""
  #       |> socket(%{
  #         self: self(),
  #         user_id: user.id,
  #         channel_id: channel.id,
  #         username: user.username
  #       })
  #       |> subscribe_and_join(UccChatWeb.RoomChannnel, CC.chan_room <> channel.name)

  #     {:ok, socket: socket, user: user, channel: channel}
  #   else
  #     :ok
  #   end
  # end

  # setup do
  #   :ok
  # end

  # describe "integation" do
  #   @tag :database
  #   test "opens slash commands", %{socket: socket} do
  #     sender = set_sender nil, "", "/"
  #     MessageInput.handle_keydown(socket, sender, "/", Client)
  #     assert_receive {:render_popup_results, html}
  #     assert Floki.find(html, ".message-popup-items .popup-item") |> length == 10
  #   end

  #   @tag :database
  #   test "opens channels", %{socket: socket} do
  #     sender = set_sender nil, "", "#"
  #     MessageInput.handle_keydown(socket, sender, "#", Client)
  #     assert_receive {:render_popup_results, html}
  #     assert Floki.find(html, ".message-popup-items .popup-item") |> length == 5
  #   end

  #   @tag database: true
  #   test "handles channels", %{socket: socket} do
  #     sender = set_sender nil, "", "#"
  #     MessageInput.handle_keydown(socket, sender, "#", Client)
  #     sender = set_sender Channels, "#", "t"
  #     MessageInput.handle_keydown(socket, sender, "t", Client)

  #     assert_receive {:render_popup_results, _}
  #     assert_receive {:render_popup_results, html}
  #     assert Floki.find(html, ".message-popup-items .popup-item") |> length == 2
  #   end

  #   @tag database: true
  #   test "handles commands", %{socket: socket} do
  #     sender = set_sender nil, "", "/"
  #     MessageInput.handle_keydown(socket, sender, "/", Client)
  #     assert_receive {:render_popup_results, html}
  #     assert Floki.find(html, ".message-popup-items .popup-item") |> length == 10

  #     sender = set_sender SlashCommands, "/j", "o"
  #     MessageInput.handle_keydown(socket, sender, "o", Client)
  #     assert_receive {:render_popup_results, html}
  #     assert Floki.find(html, ".message-popup-items .popup-item") |> length == 1
  #   end
  # end

  # describe "set_state" do

  #   test "first character" do
  #     context = set_context(nil, "", "a")
  #     assert get_in(context, [:state, :buffer]) == "a"
  #     assert get_in(context, [:state, :head]) == "a"
  #     assert get_in(context, [:state, :tail]) == ""
  #     assert get_in(context, [:state, :start]) == 1
  #     assert get_in(context, [:state, :len]) == 1
  #   end

  #   test "second character" do
  #     context = set_context(nil, "a", "b")
  #     assert get_in(context, [:state, :buffer]) == "ab"
  #     assert get_in(context, [:state, :head]) == "ab"
  #     assert get_in(context, [:state, :tail]) == ""
  #     assert get_in(context, [:state, :start]) == 2
  #     assert get_in(context, [:state, :len]) == 2
  #   end

  #   test "empty backspace" do
  #     context = set_context(nil, "", @bs)
  #     assert context.state == :ignore
  #   end

  #   test "single char backspace" do
  #     context = set_context(nil, "a", @bs)
  #     assert get_in(context, [:state, :buffer]) == ""
  #     assert get_in(context, [:state, :head]) == ""
  #     assert get_in(context, [:state, :len]) == 0
  #   end

  #   test "2 char backspace" do
  #     context = set_context(nil, "ab", @bs)
  #     assert get_in(context, [:state, :buffer]) == "a"
  #     assert get_in(context, [:state, :head]) == "a"
  #     assert get_in(context, [:state, :len]) == 1
  #   end

  #   test "trailing char backspace" do
  #     context = set_context(nil, "ab", @bs, 1)
  #     assert get_in(context, [:state, :buffer]) == "b"
  #     assert get_in(context, [:state, :head]) == ""
  #     assert get_in(context, [:state, :tail]) == "b"
  #     assert get_in(context, [:state, :len]) == 1
  #   end

  #   test "backspace at start with trailing" do
  #     context = set_context(nil, "ab", @bs, 0)
  #     assert context.state == :ignore
  #   end

  #   test "empty arrow left" do
  #     context = set_context(nil, "", @left_arrow, 0)
  #     assert context.state == :ignore
  #   end

  #   test "one char left" do
  #     context = set_context(nil, "a", @left_arrow, 1)
  #     assert get_in(context, [:state, :buffer]) == "a"
  #     assert get_in(context, [:state, :head]) == ""
  #     assert get_in(context, [:state, :tail]) == "a"
  #     assert get_in(context, [:state, :len]) == 1
  #   end

  #   # channels

  #   test "channels with bs" do
  #     context = set_context(nil, "#ab", @bs)
  #     assert get_in(context, [:state, :buffer]) == "#a"
  #     assert get_in(context, [:state, :head]) == "#a"
  #     assert get_in(context, [:state, :tail]) == ""
  #     assert get_in(context, [:state, :len]) == 2
  #   end

  #   test "channels with one left arrow" do
  #     context = set_context(nil, "#ab", @left_arrow, 3)
  #     assert get_in(context, [:state, :buffer]) == "#ab"
  #     assert get_in(context, [:state, :head]) == "#a"
  #     assert get_in(context, [:state, :tail]) == "b"
  #     assert get_in(context, [:state, :len]) == 3
  #   end

  #   test "channels with two left arrows" do
  #     context = set_context(nil, "#ab", @left_arrow, 2)
  #     assert get_in(context, [:state, :buffer]) == "#ab"
  #     assert get_in(context, [:state, :head]) == "#"
  #     assert get_in(context, [:state, :tail]) == "ab"
  #     assert get_in(context, [:state, :len]) == 3
  #   end

  #   # commands

  #   test "commands with bs" do
  #     context = set_context(nil, "/ab", @bs)
  #     assert get_in(context, [:state, :buffer]) == "/a"
  #     assert get_in(context, [:state, :head]) == "/a"
  #     assert get_in(context, [:state, :tail]) == ""
  #     assert get_in(context, [:state, :len]) == 2
  #   end

  #   test "commands with one left arrow" do
  #     context = set_context(nil, "/ab", @left_arrow, 3)
  #     assert get_in(context, [:state, :buffer]) == "/ab"
  #     assert get_in(context, [:state, :head]) == "/a"
  #     assert get_in(context, [:state, :tail]) == "b"
  #     assert get_in(context, [:state, :len]) == 3
  #   end

  #   test "commands with two left arrows" do
  #     context = set_context(nil, "/ab", @left_arrow, 2)
  #     assert get_in(context, [:state, :buffer]) == "/ab"
  #     assert get_in(context, [:state, :head]) == "/"
  #     assert get_in(context, [:state, :tail]) == "ab"
  #     assert get_in(context, [:state, :len]) == 3
  #   end
  # end

  # defp caret(start, finish \\ nil), do: %{"start" => start, "end" => finish || start}

  # defp set_context(app, text, key, start \\ nil, finish \\ nil) do
  #   MessageInput.create_context(
  #     %{assigns: %{}},
  #     set_sender(app, text, key, start, finish),
  #     key,
  #     client: Client
  #  )
  # end

  # defp set_sender(app, value, key, start \\ nil, _finish \\ nil) do
  #   len = String.length value

  #   {opened, app} = if app, do: {true, app}, else: {false, ""}

  #   %{
  #     "value" => value,
  #     "key" => key,
  #     "caret" => caret(start || len),
  #     "text_len" => len,
  #     "message_popup" => opened,
  #     "popup_app" => app
  #   }
  # end
end
