defmodule InfinityOne.Application do
  use Application

  @doc """
  Code to be run when the application starts.
  """
  def start(type, args) do
    import Supervisor.Spec

    # allow plugin access by it name
    # i.e. Application.get_env(:infinity_one, :router)

    InfinityOne.TabBar.initialize()

    Unbrella.apply_plugin_config()

    Unbrella.start type, args

    Unbrella.set_js_plugins(:infinity_one)

    setup_uploads_link()

    children =
      Unbrella.application_children()
      |> Enum.map(fn {mod, fun, args} ->
        apply mod, fun, args
      end)
      |> List.flatten

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(InfinityOne.Repo, []),
      # Start the endpoint when the application starts
      supervisor(InfinityOneWeb.Endpoint, []),
      supervisor(InfinityOneWeb.Presence, []),
      worker(InfinityOne.Permissions, []),
      worker(InfinityOne.OnePubSub, []),
    ] ++ children

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InfinityOne.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def setup_uploads_link do
    case Application.get_env :infinity_one, :release_simlink_uploads do
      {link, target} ->
        app_dir = Application.app_dir(:infinity_one)
        link_path = Path.join([app_dir | ~w(priv static #{link})])

        unless File.exists?(link_path) do
          File.ln_s(target, link_path)
        end
      _ -> nil
    end
  end

end
