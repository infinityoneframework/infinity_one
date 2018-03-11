defmodule OneSettingsTest do
  use OneSettings.DataCase
  doctest OneSettings

  alias InfinityOne.Settings.General

  setup do
    OneSettings.init_all
    :ok
  end

  test "load_all" do
    refute General.site_name == "Test"
    General.update :site_name, "Test"
    settings = OneSettings.get_all
    assert settings.general.site_name == "Test"
  end

  test "getters" do
    assert OneSettings.grouping_period_seconds == 300
    assert OneSettings.maximum_file_upload_size_kb == 2000
    assert OneSettings.enable_favorite_rooms == true
    assert OneSettings.content_home_title == "Home"
  end

end
