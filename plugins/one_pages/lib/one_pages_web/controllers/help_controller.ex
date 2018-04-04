defmodule OnePagesWeb.HelpController do
  use OnePagesWeb, :controller

  plug(:put_layout, {OnePagesWeb.LayoutView, "help.html"})

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    render(conn, id <> ".html")
  end

end
