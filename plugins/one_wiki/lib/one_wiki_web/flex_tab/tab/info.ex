defmodule OneWikiWeb.FlexBar.Tab.Info do
  @moduledoc """
  OneWiki Info Flex Tab.
  """
  use OneChatWeb.FlexBar.Helpers
  use OneLogger

  alias InfinityOne.{TabBar.Tab}
  alias InfinityOne.{TabBar}
  alias OneWikiWeb.FlexBarView
  # alias OneChatWeb.RebelChannel.Client
  alias OneWiki.Page
  alias OneWiki.Settings.Wiki, as: Settings

  @doc """
  Show Info about the page.
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[wiki],
      "wiki_info",
      ~g"Info",
      "icon-info-circled",
      FlexBarView,
      "info.html",
      10,
      [
        model: Page,
        prefix: "page"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Info panel.
  """
  def args(socket, {user_id, _channel_id, _, _,}, _params) do
    current_user = Helpers.get_user! user_id
    opts = get_opts()
    page = socket.assigns[:page]
    history_enabled = Settings.wiki_history_enabled

    log =
      if history_enabled do
        case page && OneWiki.Git.log(page.title, ["--follow"]) do
          nil -> nil
          {:error, _error} -> []
          results -> results
        end
      else
        false
      end

    {[
      current_user: current_user,
      changeset: Page.change(page),
      opts: opts,
      page: page,
      log: log,
      history_enabled: history_enabled
    ], socket}
  end

  def resource_id(socket, _, _) do
    Map.get(socket.assigns[:page] || %{}, :id)
  end


  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, _sender) do
    socket
  end

  def get_opts do
    %{
    }
  end

end
