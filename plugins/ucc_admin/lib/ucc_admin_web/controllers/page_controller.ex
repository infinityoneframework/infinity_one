defmodule UccAdminWeb.PageController do
  use UccAdminWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
