defmodule UcxUcc.Web.MasterController do
  use UcxUcc.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def phone(conn, _params) do
    render conn, "phone.html"
  end
end
