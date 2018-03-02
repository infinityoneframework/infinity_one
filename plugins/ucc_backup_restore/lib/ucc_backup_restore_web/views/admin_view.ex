defmodule UccBackupRestoreWeb.AdminView do
  @moduledoc """
  Backup and Restore plug-in administration section page view.
  """
  use UccBackupRestoreWeb, :view

  @doc """
  The web url for the backup files.
  """
  def backup_url(%{base_name: base_name}) do
    Path.join(["/", "backups", base_name])
  end
end
