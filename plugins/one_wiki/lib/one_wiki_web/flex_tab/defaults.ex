defmodule OneWikiWeb.FlexBar.Defaults do
  @moduledoc """
  Adds all the Backup and Restore Admin Flex Tab buttons.
  """
  use InfinityOneWeb.Gettext

  @doc """
  Add the Backup and Restore Flex Tab Buttons.
  """
  def add_buttons do
    # [Backup, Restore, Upload]
    [Info, MembersList]
    |> Enum.each(fn module ->
      OneWikiWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)
  end
end
