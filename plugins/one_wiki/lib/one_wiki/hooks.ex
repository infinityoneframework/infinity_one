defmodule OneWiki.Hooks do
  use Unbrella.Hooks, :add_hooks

  add_hook :one_chat_channel_controller_channels, [:list] do
    [OneWikiWeb.WikiChannel | list]
  end

  add_hook :sidenav_lists, [:list, :user] do
    [OneWikiWeb.SidenavView.render("show.html", [user: user]) | list]
  end
end
