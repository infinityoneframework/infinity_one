defmodule InfinityOneWeb.LandingController do
  use InfinityOneWeb, :controller
  use Rebel.Controller, channels: [
    InfinityOneWeb.LandingChannel
  ]

  def index(conn, _params) do
    conn
    |> put_layout("landing.html")
    |> render("index.html")
  end
end
