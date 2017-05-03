defmodule UccChat.Web.PageController do
  use UccChat.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
