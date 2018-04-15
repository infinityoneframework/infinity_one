defmodule OneWikiWeb.Admin do

  alias OneWikiWeb.Admin.Page.Wiki

  def add_pages(list) do
    [Wiki.add_page | list]
  end

end
