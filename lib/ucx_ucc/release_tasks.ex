defmodule UcxUcc.ReleaseTasks do
  @moduledoc """
  Helper commands for working with production releases.

  Set of helper functions mainly around database creation and migration.
  """
  alias UcxUcc.Repo

  require Logger

  @start_apps [
    :crypto,
    :ssl,
    :mariaex,
    :ecto,
    :coherence
  ]

  # def myapp, do: Application.get_application(__MODULE__) |> IO.inspect(label: "myapp")
  def myapp, do: :ucx_ucc

  @doc """
  Get the path of the migration files.
  """
  @spec migrations_path() :: String.t
  def migrations_path() do
    Path.join [Application.app_dir(myapp()) | ~w(priv repo migrations)]
  end

  @doc """
  Get the list of configures Repos.
  """
  @spec repos() :: [atom]
  def repos() do
    Application.get_env(myapp(), :ecto_repos) |> IO.inspect(label: "repos")
  end

  @spec load() :: :ok
  def load do
    me = myapp()

    IO.puts "Loading #{me}.."
    # Load the code for myapp, but don't start it
    Application.load(me) |> IO.inspect(label: "load me")

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(repos(), &(&1.start_link(pool_size: 10)))
  end

  @doc """
  Create the database for each configured Repo.
  """
  @spec create(boolean) :: :ok
  def create(load? \\ true) do
    if load?, do: load()

    Enum.each repos(), fn repo ->
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          Logger.info "Created repo #{inspect repo}"
        {:error, :already_up} ->
          Logger.info "Repo #{inspect repo} is already up"
        {:error, term} ->
          Logger.error "Repo #{inspect repo} returned error #{inspect term}"
      end
    end
    if load?, do: :init.stop()
  end

  @doc """
  Run all migrations.
  """
  @spec migrate(boolean) :: []
  def migrate(load? \\ true) do
    if load?, do: load()

    Ecto.Migrator.run Repo, migrations_path(), :up, all: true

    if load?, do: :init.stop()
  end

  @spec seed(boolean) :: any
  def seed(load? \\ true) do
    if load?, do: load()

    Enum.each(repos(), &run_seeds_for/1)

    if load?, do: :init.stop()
  end

  @spec setup() :: any
  def setup do
    load()
    create(false)
    migrate(false)
    seed(false)
  end

  @doc """
  Drop the database for each configured Repo.
  """
  @spec drop() :: :ok
  def drop do
    Enum.each repos(), &drop/1
  end

  @doc """
  Drop a specific Repo.
  """
  @spec drop(atom) :: :ok | {:error, :already_down} | {:error, term}
  def drop(repo) do
    case repo.__adapter__.storage_down(repo.config) do
      :ok ->
        Logger.info "Repo #{inspect repo} closed down"
        :ok
      {:error, :already_down} = ret ->
        Logger.info "Repo #{inspect repo} is already down"
        ret
      {:error, term} = ret ->
        Logger.error "Repo #{inspect repo} returned error #{inspect term}"
        ret
    end
  end


  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  # defp run_migrations_for(repo) do
  #   app = Keyword.get(repo.config, :otp_app)
  #   IO.puts "Running migrations for #{app}"
  #   Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  # end

  def run_seeds_for(repo) do
    # Run the seed script if it exists
    seed_script = seeds_path(repo)
    if File.exists?(seed_script) do
      IO.puts "Running seed script.."
      Code.eval_file(seed_script)
    end
  end

  def migrations_path(repo), do: priv_path_for(repo, "migrations")

  def seeds_path(repo), do: priv_path_for(repo, "seeds_prod.exs")

  def priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split |> List.last |> Macro.underscore
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
