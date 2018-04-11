defmodule OneWikiWeb.SidenavView do
  use OneWikiWeb, :view

  alias OneWiki.Page

  def get_pages(user) when user == %{} do
    OneWiki.Page.list()
  end

  def get_pages(user) do
    Page.get_visible_subscribed_for_user(user)
  end

  def name(%{title: title}) do
    name(title)
  end

  def name(title) when is_binary(title) do
    String.slice(title, 0, 20)
  end

  def page_opts(%{subscription: nil}) do
    label = ~g(Add)
    raw "<i aria-label='#{label}' class='icon-plus' title='#{label}' rebel-click='subscribe_page'></i>"
  end
  def page_opts(%{subscription: %{hidden: true}}) do
    label = ~g(Hidden)
    raw "<i aria-label='#{label}' class='icon-eye-off' title='#{label}' rebel-click='unhide_page'></i>"
  end

  def page_opts(%{}) do
    label = ~g(Open)
    raw "<i aria-label='#{label}' class='icon-eye' title='#{label}' rebel-click='show_page'></i>"
  end

end
