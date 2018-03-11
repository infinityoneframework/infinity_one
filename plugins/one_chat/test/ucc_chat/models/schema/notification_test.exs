defmodule OneChat.Schema.NotificationTest do
  use ExUnit.Case, async: true

  alias OneChat.Schema.Notification

  @settings_attrs %{}
  @valid_attrs %{settings: @settings_attrs,
    channel_id: "73a8bcc9-859e-497d-bb0c-205c0a3b8d5b"}
  @invalid_attrs %{}

  test "valid changeset" do
    assert Notification.changeset(%Notification{}, @valid_attrs).valid?
  end

  test "invalid changeset" do
    refute Notification.changeset(%Notification{}, @invalid_attrs).valid?
  end
end
