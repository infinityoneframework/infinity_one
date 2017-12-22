defmodule UcxUcc.Application do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(type, args) do
    import Supervisor.Spec

    # allow plugin access by it name
    # i.e. Application.get_env(:ucc_ucx, :router)

    UcxUcc.TabBar.initialize()

    Unbrella.apply_plugin_config()

    Unbrella.start type, args

    Unbrella.set_js_plugins(:ucx_ucc)

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
      supervisor(UcxUccWeb.Endpoint, []),
      supervisor(UcxUccWeb.Presence, []),
      worker(UcxUcc.Permissions, []),
      worker(UcxUcc.UccPubSub, []),
    ] ++ children

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UcxUcc.Supervisor]
    spawn(fn ->
      receive do
        :run ->
          create_and_migrate_db()
      end
    end)
    |> Process.send_after(:run, 1000)

    Supervisor.start_link(children, opts)
  end

  @doc """
  Run the database create and migrate.

  Ensure the database is ready for the application.
  """
  def create_and_migrate_db() do
    Logger.info "Running Mix.create and Mix.update"
    UcxUcc.Mix.create
    UcxUcc.Mix.update
  end

end
