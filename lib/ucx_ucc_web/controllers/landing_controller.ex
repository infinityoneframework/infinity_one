defmodule UcxUccWeb.LandingController do
  use UcxUccWeb, :controller
  use Rebel.Controller, channels: [
    UcxUccWeb.LandingChannel
  ]

  def index(conn, _params) do
    conn
    |> put_layout("landing.html")
    |> render("index.html")
  end
end
