defmodule UccChatWeb.HomeController do
  use UccChatWeb, :controller
  require Logger
  alias UccChat.{ChatDat}
  alias UccChat.ServiceHelpers, as: Helpers

  def index(conn, _params) do
    case Helpers.get_user(Coherence.current_user(conn) |> Map.get(:id)) do
      nil ->
        UcxUccWeb.Coherence.SessionController.delete(conn, %{})
      user ->
        chatd = ChatDat.new(user)
        conn
        |> put_layout({UcxUccWeb.LayoutView, "app.html"})
        |> put_view(UccChatWeb.HomeView)
        |> render("index.html", chatd: chatd)
    end
  end

end
