defmodule UcxUcc.Web.PageController do
  use UcxUcc.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
