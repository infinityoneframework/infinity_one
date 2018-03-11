defmodule InfinityOne.Plugs.Setup do
  @moduledoc """
  Plug to redirect the user to setup page after fresh install.
  """
  @behaviour Plug

  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias InfinityOne.Accounts

  @doc false
  def init(options) do
    %{options: options}
  end

  @doc false
  def call(conn, opts \\ [])

  # don't allow users already logged in to use the landing page
  # def call(%{path_info: ["landing"], cookies: %{"_infinity_one_key" => cookies}} = conn, _opts) do
  #   IO.inspect cookies, label: "cookies"
  #   conn
  #   |> redirect(to: "/")
  #   |> halt
  # end
  def call(%{path_info: []} = conn, _opts) do
    if length(Accounts.list_users()) > 1 do
      conn
    else
      conn
      |> redirect(to: "/landing")
      |> halt
    end
  end

  # only allow logged out users access when only the Bot account is configured
  def call(%{path_info: ["landing"]} = conn, _opts) do
    if length(Accounts.list_users()) > 1 do
      conn
      |> redirect(to: "/")
      |> halt
    else
      conn
    end
  end

  def call(conn, _opts) do
    cond do
      conn.cookies["_infinity_one_key"] ->
        # user is already logged in
        conn
      length(Accounts.list_users()) > 1 ->
        # already have the system setup
        conn
      true ->
        # need to run the setup
        conn
        |> redirect(to: "/landing")
        |> halt
    end
  end
end
