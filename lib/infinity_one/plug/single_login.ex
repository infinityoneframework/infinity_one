defmodule InfinityOne.Plug.SingleLogin do
  @moduledoc """
  Plug to allow only one login per user.

  Checks to see if another device is logged in for the user. If it finds other
  logins, it logs them out.
  """
  @behaviour Plug

  import Plug.Conn

  alias InfinityOne.OnePubSub
  alias Coherence.CredentialStore.Server

  require Logger

  @session_key Application.get_env(:coherence, :session_key, "session_auth")

  def init(opts) do
   %{
      store: Keyword.get(opts, :store, Coherence.CredentialStore.Session),
      assigns_key: Keyword.get(opts, :assigns_key, :current_user),
      login_key: Keyword.get(opts, :login_cookie, Coherence.Config.login_cookie),
   }
  end

  def call(conn, opts) do
    do_call(conn, opts, Process.whereis(Server))
  end

  defp do_call(conn, _opts, nil) do
    conn
  end

  defp do_call(conn, opts, pid) do
    user = conn.assigns.current_user
    logins =
      pid
      |> :sys.get_state()
      |> Map.get(:store)
      |> Enum.filter(& elem(&1, 1) == user.id)

    if length(logins) == 1  do
      conn
    else
      key = get_session(conn, @session_key)
      if is_nil(key), do: raise("Cannot find the session")

      logins
      |> Enum.reject(& elem(&1, 0) == key)
      |> Enum.reduce(conn, fn {creds, _}, acc ->
        opts.store.delete_credentials(creds)
        OnePubSub.broadcast("user:" <> user.id, "logout", %{creds: creds})
        acc
      end)
    end
  end
end
