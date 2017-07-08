defmodule UccChatTest.Settings do
  use UccChat.DataCase

  alias UccChat.Settings

  setup do
    UccSettings.init_all
    :ok
  end

  test "getters" do
    assert Settings.grouping_period_seconds == 300
    assert Settings.maximum_file_upload_size_kb == 2000
    assert Settings.enable_favorite_rooms == true
    assert Settings.content_home_title == "Home"
  end

end
