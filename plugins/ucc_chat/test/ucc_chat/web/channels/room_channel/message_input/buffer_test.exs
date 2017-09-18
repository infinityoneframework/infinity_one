defmodule UccChatWeb.RoomChannel.MessageInput.BufferTest do
  use UccChatWeb.ChannelCase
  use UccChatWeb.RoomChannel.Constants

  # import UccChat.TestHelpers

  alias UccChatWeb.RoomChannel.MessageInput.Buffer

  describe "replace_word" do
    test "channel #" do
      assert Buffer.replace_word("#", "ab", 1) == "#ab"
      assert Buffer.replace_word("#", "ab", 2) == "#ab"
      assert Buffer.replace_word("#Test", "Sub", 5) == "#Sub"
      assert Buffer.replace_word("#Test", "Sub", 1) == "#Sub"
    end
    test "channel in middle" do
      assert Buffer.replace_word("#A ab", "Sub", 2) == "#Sub ab"
      assert Buffer.replace_word("#Abc ab #Ft", "Sub", 2) == "#Sub ab #Ft"
      assert Buffer.replace_word("#Abc ab #Ft", "Sub", 9) == "#Abc ab #Sub"
    end
    test "users" do
      assert Buffer.replace_word("@", "ab", 2) == "@ab"
      assert Buffer.replace_word("@Test", "Sub", 5) == "@Sub"
      assert Buffer.replace_word("@Test", "Sub", 1) == "@Sub"
      assert Buffer.replace_word("@A ab", "Sub", 2) == "@Sub ab"
      assert Buffer.replace_word("@Abc ab @Ft", "Sub", 2) == "@Sub ab @Ft"
      assert Buffer.replace_word("@Abc ab @Ft", "Sub", 9) == "@Abc ab @Sub"
    end
    test "emojis" do
      assert Buffer.replace_word(":", "ab", 2) == ":ab"
      assert Buffer.replace_word(":Test", "Sub", 5) == ":Sub"
      assert Buffer.replace_word(":Test", "Sub", 1) == ":Sub"
      assert Buffer.replace_word(":A ab", "Sub", 2) == ":Sub ab"
      assert Buffer.replace_word(":Abc ab :Ft", "Sub", 2) == ":Sub ab :Ft"
      assert Buffer.replace_word(":Abc ab :Ft", "Sub", 9) == ":Abc ab :Sub"
    end
    test "commands" do
      assert Buffer.replace_word("/", "ab", 1) == "/ab"
      assert Buffer.replace_word("/", "ab", 2) == "/ab"
      assert Buffer.replace_word("/test other", "ab", 2) == "/ab other"
      assert Buffer.replace_word("a /test other", "ab", 4) == "a /test other"
    end
  end

  describe "match_app_pattern" do
    test "commands" do
      assert Buffer.match_app_pattern("/") == ""
      assert Buffer.match_app_pattern("/a") == "a"
      assert Buffer.match_app_pattern("/ab") == "ab"
      refute Buffer.match_app_pattern(" /")
      refute Buffer.match_app_pattern(" /ab")
    end

  end

  describe "get_buffer_state" do
    test "CR end" do
      sender = build_sender "ab", 2, 2
      assert Buffer.get_buffer_state(sender, @cr) == %{
        head: "ab",
        tail: "",
        start: 2,
        len: 2,
        buffer: "ab"
      }
    end
    test "CR middle" do
      sender = build_sender "hi #big and #Accounting ", 7, 7
      assert Buffer.get_buffer_state(sender, @cr) == %{
        head: "hi #big",
        tail: " and #Accounting ",
        start: 7,
        len: 24,
        buffer: "hi #big and #Accounting "
      }
    end
    test "Tab end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @tab) == %{
        head: "ab",
        tail: "",
        start: 2,
        len: 2,
        buffer: "ab"
      }
    end

    test "Left Arrow end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @left_arrow) == %{
        head: "a",
        tail: "b",
        start: 1,
        len: 2,
        buffer: "ab"
      }
    end

    test "Left Arrow middle" do
      sender = build_sender "ab", 1
      assert Buffer.get_buffer_state(sender, @left_arrow) == %{
        head: "",
        tail: "ab",
        start: 0,
        len: 2,
        buffer: "ab"
      }
    end

    test "Right Arrow end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @right_arrow) == :ignore
    end

    test "Right Arrow second last" do
      sender = build_sender "ab", 1
      assert Buffer.get_buffer_state(sender, @right_arrow) == %{
        head: "ab",
        tail: "",
        start: 2,
        len: 2,
        buffer: "ab"
      }
    end

    test "Down Arrow end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @dn_arrow) == %{
        head: "ab",
        tail: "",
        start: 2,
        len: 2,
        buffer: "ab"
      }
    end

    test "Down Arrow middle" do
      sender = build_sender "ab", 1
      assert Buffer.get_buffer_state(sender, @dn_arrow) == %{
        head: "a",
        tail: "b",
        start: 1,
        len: 2,
        buffer: "ab"
      }
    end

    test "Up Arrow end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @up_arrow) == %{
        head: "ab",
        tail: "",
        start: 2,
        len: 2,
        buffer: "ab"
      }
    end

    test "Up Arrow middle" do
      sender = build_sender "ab", 1
      assert Buffer.get_buffer_state(sender, @up_arrow) == %{
        head: "a",
        tail: "b",
        start: 1,
        len: 2,
        buffer: "ab"
      }
    end

    test "bs start" do
      sender = build_sender "ab", 0
      assert Buffer.get_buffer_state(sender, @bs) == :ignore
    end

    test "bs empty" do
      sender = build_sender "", 0
      assert Buffer.get_buffer_state(sender, @bs) == :ignore
    end

    test "bs end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, @bs) == %{
        head: "a",
        tail: "",
        start: 1,
        len: 1,
        buffer: "a"
      }
    end

    test "char end" do
      sender = build_sender "ab", 2
      assert Buffer.get_buffer_state(sender, "c") == %{
        head: "abc",
        tail: "",
        start: 3,
        len: 3,
        buffer: "abc"
      }
    end
    test "char middle" do
      sender = build_sender "ac", 1
      assert Buffer.get_buffer_state(sender, "b") == %{
        head: "ab",
        tail: "c",
        start: 2,
        len: 3,
        buffer: "abc"
      }
    end
  end

  defp build_sender(value, start, finish \\ nil) do
    finish = finish || start
    %{
      "value" => value,
      "caret" => %{"end" => finish, "start" => start},
      "text_len" => String.length(value)
    }
  end
end

