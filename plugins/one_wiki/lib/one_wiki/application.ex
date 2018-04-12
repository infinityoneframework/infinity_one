defmodule OneWiki.Application do
  @moduledoc """
  The OneWiki start up handler
  """
  require Logger

  @doc """
  Start handler.

  Try initializing the file storage.
  """
  def start(_type, _args) do
    OneWikiWeb.FlexBar.Defaults.add_buttons()
    try do
      OneWiki.initialize()
    rescue
      e in RuntimeError ->
        Logger.error("Could not initialize the OneWiki file storage. " <> e.message)
      _ ->
        Logger.error("Could not initialize the OneWiki file storage.")
    end
  end
end
