defmodule UccBackupRestoreWeb.Admin do
  @moduledoc """
  Admin pages hooks implementation.

  Adds Backup & Restore Admin pages at startup.
  """
  alias UccBackupRestoreWeb.Admin.Page.BackupRestore

  def add_pages(list) do
    [BackupRestore.add_page() | list]
  end
end
