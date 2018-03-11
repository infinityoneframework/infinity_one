defmodule OneBackupRestore.Backup do
  use OneModel, schema: OneBackupRestore.Schema.Backup

  alias OneBackupRestore.Schema.Backup

  def change do
    Backup.changeset(%Backup{})
  end
end
