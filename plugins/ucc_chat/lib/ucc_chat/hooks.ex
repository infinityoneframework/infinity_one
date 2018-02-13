defmodule UccChat.Hooks do
  @moduledoc """
  A Hook implementation for the UccChat plugin.
  """
  use Unbrella.Hooks, :add_hooks
  alias UcxUcc.Repo

  require Logger

  add_hook :preload_user, [:user, :preload] do
    Logger.debug fn -> "preload_user, preload: #{inspect preload}" end
    Repo.preload user, preload
  end

  add_hook :register_admin_pages, UccChatWeb.Admin, :add_pages
end
