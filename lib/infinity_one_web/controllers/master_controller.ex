defmodule InfinityOneWeb.MasterController do
  use InfinityOneWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def phone(conn, _params) do
    render conn, "phone.html"
  end
end
