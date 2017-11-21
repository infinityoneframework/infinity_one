defmodule UccDialerTest do
  use ExUnit.Case, async: true
  doctest UccDialer

  @pattern "1, NXXNXXXXXX"

  test "translates" do
    assert UccDialer.translate_digits("5555", @pattern) == "5555"
    assert UccDialer.translate_digits("5555555555", @pattern) == "15555555555"
    assert UccDialer.translate_digits("15555555555", @pattern) == "15555555555"
  end
end
