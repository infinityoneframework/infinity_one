defmodule UccBackupRestoreWeb.FlexBar.Defaults do
  @moduledoc """
  Adds all the Backup and Restore Admin Flex Tab buttons.
  """
  use UcxUccWeb.Gettext

  @doc """
  Add the Backup and Restore Flex Tab Buttons.
  """
  def add_buttons do
    # [Backup, Restore, Upload]
    [Backup, Restore, GenCert]
    |> Enum.each(fn module ->
      UccBackupRestoreWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)
  end
end
