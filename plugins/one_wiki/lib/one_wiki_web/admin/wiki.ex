defmodule OneWikiWeb.Admin.Page.Wiki do
  use OneAdmin.Page

  import InfinityOneWeb.Gettext

  alias InfinityOne.{Repo, Hooks}
  alias OneWiki.Settings.Wiki

  def add_page do
    new(
      "admin_wiki",
      __MODULE__,
      ~g(Wiki Pages),
      OneWikiWeb.AdminView,
      "wiki.html",
      115,
      pre_render_check: &check_perissions/2,
      permission: "view-pages-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Wiki.get |> Wiki.changeset,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-pages-administration"
  end
end
