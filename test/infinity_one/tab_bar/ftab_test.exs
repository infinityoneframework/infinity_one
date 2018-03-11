defmodule InfinityOne.TabBar.FtabTest do
  use ExUnit.Case
  doctest InfinityOne.TabBar.Ftab

  alias InfinityOne.TabBar
  # alias TabBar.Ftab

  setup do
    TabBar.delete_all
    :ok
  end

  # test "opens previous view" do
  #   Ftab.open 1, 1, "test", %{name: "A"}
  #   assert Ftab.open?(1, 1, "test")
  #   Ftab.open 1, 1, "other", nil
  #   Ftab.open 1, 1, "test", nil
  #   assert Ftab.get(1, 1) == {"test", %{name: "A"}}
  # end

end
