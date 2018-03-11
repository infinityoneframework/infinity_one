defmodule OneDialerTest do
  use ExUnit.Case, async: true
  doctest OneDialer

  @pattern "1, NXXNXXXXXX"

  test "translates" do
    assert OneDialer.translate_digits("5555", @pattern) == "5555"
    assert OneDialer.translate_digits("5555555555", @pattern) == "15555555555"
    assert OneDialer.translate_digits("15555555555", @pattern) == "15555555555"
  end
end
