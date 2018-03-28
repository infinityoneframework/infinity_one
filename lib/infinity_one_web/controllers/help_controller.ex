defmodule InfinityOneWeb.HelpController do
  use InfinityOneWeb, :controller

  plug(:put_layout, {InfinityOneWeb.LayoutView, "help.html"})

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    render(conn, id <> ".html")
  end
end
