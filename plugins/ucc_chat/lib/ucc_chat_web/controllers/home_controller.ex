defmodule UccChatWeb.HomeController do
  use UccChatWeb, :controller
  require Logger
  alias UccChat.{ChatDat}
  alias UccChat.ServiceHelpers, as: Helpers

  def index(conn, _params) do
    user = Helpers.get_user!(Coherence.current_user(conn) |> Map.get(:id))

    chatd = ChatDat.new(user)
    conn
    |> put_layout({UcxUccWeb.LayoutView, "app.html"})
    |> render("index.html", chatd: chatd)
  end

end
