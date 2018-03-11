defmodule OneChatWeb.HomeController do
  use OneChatWeb, :controller
  require Logger
  alias OneChat.{ChatDat}
  alias OneChat.ServiceHelpers, as: Helpers

  def index(conn, _params) do
    case Helpers.get_user(Coherence.current_user(conn) |> Map.get(:id)) do
      nil ->
        InfinityOneWeb.Coherence.SessionController.delete(conn, %{})
      user ->
        chatd = ChatDat.new(user)
        conn
        |> put_layout({InfinityOneWeb.LayoutView, "app.html"})
        |> put_view(OneChatWeb.HomeView)
        |> render("index.html", chatd: chatd)
    end
  end

end
