defmodule UcxUcc.TabBarTest do
  use ExUnit.Case
  doctest UcxUcc.TabBar

  alias UcxUcc.TabBar

  setup do
    TabBar.delete_all
    :ok
  end

end
