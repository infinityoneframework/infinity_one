defmodule UccSettingsTest do
  use UccSettings.DataCase
  doctest UccSettings

  alias UcxUcc.Settings.General

  setup do
    UccSettings.init_all
    :ok
  end

  test "load_all" do
    refute General.site_name == "Test"
    General.update :site_name, "Test"
    settings = UccSettings.get_all
    assert settings.general.site_name == "Test"
  end

  test "getters" do
    assert UccSettings.grouping_period_seconds == 300
    assert UccSettings.maximum_file_upload_size_kb == 2000
    assert UccSettings.enable_favorite_rooms == true
    assert UccSettings.content_home_title == "Home"
  end

end
