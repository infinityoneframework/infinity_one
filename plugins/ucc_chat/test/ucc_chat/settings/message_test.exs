defmodule UccChatTest.Settings.Message do
  use UccChat.DataCase

  alias UccChat.Settings.Message

  setup do
    Message.init()
    {:ok, message: Message.get()}
  end

  test "has values", %{message: message} do
    assert message.hide_user_join == false
    assert message.show_edited_status == true
    assert message.time_format == "LT"
    assert message.grouping_period_seconds == 300
  end

end
