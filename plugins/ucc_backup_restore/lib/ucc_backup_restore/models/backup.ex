defmodule UccBackupRestore.Backup do
  use UccModel, schema: UccBackupRestore.Schema.Backup

  alias UccBackupRestore.Schema.Backup

  def change do
    Backup.changeset(%Backup{})
  end
end
