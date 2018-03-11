defmodule OneWebrtc.ClientDeviceTest do
  use OneWebrtc.DataCase

  unless Code.ensure_compiled?(InfinityOne.TestHelpers) do
    Code.load_file "test_helpers.ex", "./test/support"
  end

  import InfinityOne.TestHelpers
  import OneWebrtc.TestHelpers

  # alias OneWebrtc.ClientDevice

  test "create client device" do
    user = insert_user()
    device = insert_client_device(user)
    assert device.user_id == user.id
  end

  test "create client devices for same user" do
    user = insert_user()
    device1 = insert_client_device(user)
    device2 =
      device1
      |> Map.from_struct
      |> Map.delete(:id)
      |> Map.delete(:ip_addr)
      |> Map.delete(:inserted_at)
      |> Map.delete(:updated_at)
      |> insert_client_device

    assert device1.user_id == device2.user_id
    refute device1.ip_addr == device2.ip_addr
    refute device1.id == device2.id
  end
end
