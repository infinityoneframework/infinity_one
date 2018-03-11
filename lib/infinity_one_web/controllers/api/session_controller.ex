defmodule InfinityOneWeb.API.SessionController do
  use InfinityOneWeb, :controller

  require Logger

  plug :put_layout, false

  def create(conn, params) do
    Logger.warn "params: " <> inspect(params)
    _conn1 = InfinityOneWeb.Coherence.SessionController.create_api(conn, %{"tz-offset" => "0", "session" => params})
    |> IO.inspect(label: "conn")
    # json conn, %{auth_token: "asrtarst"}
  end

  def delete(conn, params) do
    Logger.warn "params: " <> inspect(params)
    conn
  end

end
