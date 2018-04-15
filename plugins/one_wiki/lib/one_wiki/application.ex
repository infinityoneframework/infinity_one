defmodule OneWiki.Application do
  @moduledoc """
  The OneWiki start up handler
  """
  alias OneWiki.Settings.Wiki, as: Settings

  require Logger

  @doc """
  Start handler.

  Try initializing the file storage.
  """
  def start(_type, _args) do
    spawn fn ->
      Process.sleep(3_000)
      settings = Settings.get()
      if settings.wiki_enabled do
        OneWikiWeb.FlexBar.Defaults.add_buttons()

        if settings.wiki_history_enabled do
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
    end
  end
end
