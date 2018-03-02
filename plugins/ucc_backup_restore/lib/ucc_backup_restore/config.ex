defmodule UccBackupRestore.Config do
  @moduledoc """
  Configuration for the Backup and Restore plug-in.
  """

  @doc """
  Get the configuration item.
  """
  def get_env(item, default \\ nil) do
    Keyword.get(do_get_env(), item, default)
  end

  defp do_get_env do
    :unbrella
    |> Application.get_env(:plugins, [])
    |> Keyword.get(:ucc_backup_restore, [])
  end
end
