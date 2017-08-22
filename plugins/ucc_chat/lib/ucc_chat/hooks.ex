defmodule UccChat.Hooks do
  use Unbrella.Hooks, :add_hooks
  alias UcxUcc.Repo

  require Logger

  add_hook :preload_user, [:user, :preload] do
    Logger.warn "preload_user, preload: #{inspect preload}"
    Repo.preload user, preload
  end

end
