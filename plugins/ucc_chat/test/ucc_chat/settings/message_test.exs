defmodule UccChatTest.Settings.Message do
  use UccChat.DataCase

  alias UccChat.Settings.Message
  alias UccChat.Settings.Schema.Message, as: Schema

  setup do
    Message.init()
    {:ok, message: Message.get()}
  end

  test "schema" do
    assert Message.schema == UccChat.Settings.Schema.Message
  end

  test "changeset" do
    changeset = Message.changeset Message.schema.__struct__, %{time_format: "aa"}
    assert changeset.data == %Schema{}
    assert changeset.valid?
    assert changeset.changes == %{time_format: "aa"}
  end

  test "has values", %{message: message} do
    assert message.hide_user_join == false
    assert message.show_edited_status == true
    assert message.time_format == "LT"
    assert message.grouping_period_seconds == 300
  end

  test "get", %{message: message} do
    assert Message.get(:time_format) == "LT"
    assert Message.get(message, :time_format) == "LT"
  end

  test "getters", %{message: message} do
    assert Message.time_format == "LT"
    assert Message.time_format(struct(message, time_format: "bb")) == "bb"
  end

  test "update", %{message: message} do
    {:ok, msgs} = Message.update :grouping_period_seconds, 100
    assert Message.get(:grouping_period_seconds) == 100
    assert msgs.grouping_period_seconds == 100

    {:ok, msgs} = Message.update struct(message, hide_user_join: true)
    assert Message.get(:hide_user_join)
    assert msgs.hide_user_join
  end
end
