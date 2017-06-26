defmodule UccAdmin.Web.PageController do
  use UccAdmin.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
