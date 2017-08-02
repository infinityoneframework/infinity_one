defmodule UcxUccWeb.PageController do
  use UcxUccWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
