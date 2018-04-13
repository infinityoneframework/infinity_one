defmodule OneBackupRestore.Application do
  @moduledoc """
  Backup and Restore Application module.

  Creates the backup path if it does not already exist.
  """

  alias OneBackupRestore.Utils
  require Logger

  def start(_, _) do
    case File.mkdir_p Utils.backup_path() do
      :ok ->
        :ok
      {:error, error} ->
        Logger.error("Could not create backup path #{Utils.backup_path()} - error: #{inspect error}")
        :error
    end
  end

end
