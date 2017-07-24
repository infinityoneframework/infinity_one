defmodule UcxUcc.TabBar.FtabTest do
  use ExUnit.Case
  doctest UcxUcc.TabBar.Ftab

  alias UcxUcc.TabBar
  # alias TabBar.Ftab

  setup do
    TabBar.delete_all
    :ok
  end

end
