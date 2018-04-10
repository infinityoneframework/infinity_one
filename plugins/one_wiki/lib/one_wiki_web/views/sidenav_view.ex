defmodule OneWikiWeb.SidenavView do
  use OneWikiWeb, :view

  def get_pages(_user) do
    OneWiki.Page.list()
  end

  def name(%{title: title}) do
    name(title)
  end

  def name(title) when is_binary(title) do
    String.slice(title, 0, 20)
  end

end
