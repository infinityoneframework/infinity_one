defmodule OneWikiWeb.FlexBar.Defaults do
  @moduledoc """
  Adds all the Wiki Flex Tab buttons.
  """
  use InfinityOneWeb.Gettext

  @doc """
  Add the Wiki Flex Tab Buttons.
  """
  def add_buttons do
    [Info, MembersList]
    |> Enum.each(fn module ->
      OneWikiWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)
  end
end
