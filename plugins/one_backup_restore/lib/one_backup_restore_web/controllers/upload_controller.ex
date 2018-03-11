defmodule OneBackupRestoreWeb.UploadController do
  use OneBackupRestoreWeb, :controller

  require Logger

  def create(conn, params) do
    Logger.warn "params: #{inspect params}"
    halt conn
  end

end
