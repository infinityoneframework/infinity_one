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

    Unbrella.set_js_plugins(:ucx_ucc)

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
    Supervisor.start_link(children, opts)
  end

  def setup_uploads_link do
    case Application.get_env :ucx_ucc, :release_simlink_uploads do
      {link, target} ->
        app_dir = Application.app_dir(:ucx_ucc)
        link_path = Path.join([app_dir | ~w(priv static #{link})])

        unless File.exists?(link_path) do
          File.ln_s(target, link_path)
        end
      _ -> nil
    end
  end

end
