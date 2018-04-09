defmodule OneWikiWeb.SidenavView do
  use OneWikiWeb, :view

  def get_pages(user) do
    OneWiki.Page.list()
  end

end
