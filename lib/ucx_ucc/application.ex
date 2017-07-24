defmodule UcxUcc.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(type, args) do
    import Supervisor.Spec

    # allow plugin access by it name
    # i.e. Application.get_env(:ucc_ucx, :router)

    UcxUcc.TabBar.initialize()

    Unbrella.apply_plugin_config()

    Unbrella.start type, args

    children =
      Unbrella.application_children()
      |> Enum.map(fn {mod, fun, args} ->
        apply mod, fun, args
      end)
      |> List.flatten

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(UcxUcc.Repo, []),
      # Start the endpoint when the application starts
      supervisor(UcxUcc.Web.Endpoint, []),
      supervisor(UcxUcc.Web.Presence, []),
      worker(UcxUcc.Permissions, []),
      worker(UcxUcc.TabBar.Agent, []),
      worker(UcxUcc.UccPubSub, []),
    ] ++ children

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UcxUcc.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
