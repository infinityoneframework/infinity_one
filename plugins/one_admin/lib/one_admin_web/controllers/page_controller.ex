defmodule OneAdminWeb.PageController do
  use OneAdminWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
