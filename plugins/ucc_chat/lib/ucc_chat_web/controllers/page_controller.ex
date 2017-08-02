defmodule UccChatWeb.PageController do
  use UccChatWeb, :controller

  import Ecto.Query

  alias Coherence.ControllerHelpers, as: Helpers
  alias UcxUcc.Repo
  alias UcxUcc.Agents.User
  # alias UccChat.Schema.Channel, as: ChannelSchema

  require Logger

  def index(conn, _params) do
    user =
      conn
      |> Coherence.current_user
      |> Repo.preload([:user])

    channel = UccChat.ChannelSchema |> Ecto.Query.first |> Repo.one
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
