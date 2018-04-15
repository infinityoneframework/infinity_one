defmodule OneWiki.Hooks do
  use Unbrella.Hooks, :add_hooks

  alias OneWiki.Settings.Wiki, as: Settings

  add_hook :one_chat_channel_controller_channels, [:list] do
    [OneWikiWeb.WikiChannel | list]
  end

  add_hook :sidenav_lists, [:list, :user] do
    if Settings.wiki_enabled do
      [OneWikiWeb.SidenavView.render("show.html", [user: user]) | list]
    else
      list
    end
  end

  add_hook :register_admin_pages, OneWikiWeb.Admin, :add_pages
end
