defmodule OneChat.Hooks do
  @moduledoc """
  A Hook implementation for the OneChat plugin.
  """
  use Unbrella.Hooks, :add_hooks
  alias InfinityOne.Repo

  require Logger

  add_hook :preload_user, [:user, :preload] do
    Logger.debug "preload_user, preload: #{inspect preload}"
    Repo.preload user, preload
  end

  add_hook :register_admin_pages, OneChatWeb.Admin, :add_pages
end
