defmodule OneChatWeb.PageController do
  use OneChatWeb, :controller

  import Ecto.Query

  alias Coherence.Controller
  alias InfinityOne.Repo
  alias InfinityOne.Agents.User
  alias OneChat.ServiceHelpers, as: Helpers
  # alias OneChat.Schema.Channel, as: ChannelSchema

  require Logger

  def index(conn, _params) do
    case Helpers.get_user(Coherence.current_user(conn) |> Map.get(:id)) do
      nil ->
        InfinityOneWeb.Coherence.SessionController.delete(conn, %{})
      user ->
        channel = OneChat.ChannelSchema |> Ecto.Query.first |> Repo.one
        render conn, "index.html", user: user, channel: channel
    end
  end

  def switch_user(conn, %{"user" => username}) do
    new_user =
      User
      |> where([u], u.username == ^username)
      |> Repo.one!

    conn
    |> Controller.logout_user()
    |> Controller.login_user(new_user)
    |> redirect(to: "/")
  end
end
