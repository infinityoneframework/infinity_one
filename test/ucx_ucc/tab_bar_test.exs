defmodule UcxUcc.TabBarTest do
  use ExUnit.Case
  doctest UcxUcc.TabBar

  alias UcxUcc.TabBar

  setup do
    TabBar.delete_all
    :ok
  end

  test "remembers open tabs when switching" do
    TabBar.open_ftab 1, 2, "test", nil
    assert TabBar.get_ftab(1, 2) == {"test", nil}
    TabBar.open_ftab 1, 2, "other", %{name: "one"}
    assert TabBar.get_ftab(1, 2) == {"other", %{name: "one"}}
    TabBar.open_ftab 1, 2, "again", %{name: "two"}
    TabBar.open_ftab 1, 2, "other", nil
    assert TabBar.get_ftab(1, 2) == {"other", %{name: "one"}}
  end
end
