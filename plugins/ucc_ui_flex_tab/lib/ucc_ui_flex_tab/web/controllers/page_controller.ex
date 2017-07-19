defmodule UccUiFlexTab.Web.PageController do
  use UccUiFlexTab.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
