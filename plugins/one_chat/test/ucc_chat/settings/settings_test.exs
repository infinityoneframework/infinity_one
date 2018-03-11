defmodule OneChatTest.Settings do
  use OneChat.DataCase

  alias OneChat.Settings

  setup do
    OneSettings.init_all
    :ok
  end

  test "getters" do
    assert Settings.grouping_period_seconds == 300
    assert Settings.maximum_file_upload_size_kb == 2000
    assert Settings.enable_favorite_rooms == true
    assert Settings.content_home_title == "Home"
  end

end
