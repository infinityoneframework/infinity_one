defmodule MscsWeb.ClientController do
  use MscsWeb, :controller

  plug :do_put_layout

  def do_put_layout(conn, _opts) do
    put_layout conn, {UcxUccWeb.LayoutView, :app}
  end

  def index(conn, _params) do
    render conn, "index.html"
  end
end
