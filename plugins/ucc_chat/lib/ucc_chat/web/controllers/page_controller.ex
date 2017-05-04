defmodule UccChat.Web.PageController do
  use UccChat.Web, :controller
  require Logger
  alias Coherence.ControllerHelpers, as: Helpers
  alias UcxUcc.Repo
  alias UcxUcc.Agents.User
  import Ecto.Query

  def index(conn, _params) do
    user = Coherence.current_user(conn)
    |> Repo.preload([:user])
    channel = UccChat.Channel |> Ecto.Query.first |> Repo.one
    Logger.info "user: #{inspect user}"
    render conn, "index.html", user: user, channel: channel
  end

  def switch_user(conn, %{"user" => username}) do
    Logger.warn "conn: #{inspect conn}"
    new_user =
      User
      |> where([u], u.username == ^username)
      |> Repo.one!
    conn
    |> Helpers.logout_user()
    |> Helpers.login_user(new_user)
    |> redirect(to: "/")
  end
end
