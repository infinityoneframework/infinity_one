defmodule WebrtcClientWeb.PageController do
  use WebrtcClientWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
