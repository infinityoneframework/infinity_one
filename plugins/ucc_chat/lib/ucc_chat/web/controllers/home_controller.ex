defmodule UccChat.Web.HomeController do
  use UccChat.Web, :controller
  require Logger
  alias UccChat.{ChatDat}
  alias UccChat.ServiceHelpers, as: Helpers

  def index(conn, _params) do
    user = Helpers.get_user!(Coherence.current_user(conn) |> Map.get(:id))

    chatd = ChatDat.new(user)
    conn
    |> put_layout({UcxUcc.Web.LayoutView, "app.html"})
    |> render("index.html", chatd: chatd)
  end

end
