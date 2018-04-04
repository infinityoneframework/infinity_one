defmodule OnePagesWeb.WhyController do
  use OnePagesWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
