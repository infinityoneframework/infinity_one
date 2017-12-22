defmodule UcxUcc.Mix do
  require Logger
  alias UcxUcc.Repo

  def migrations_path() do
    Path.join [Application.app_dir(:ucx_ucc) | ~w(priv repo migrations)]
  end

  def get_repos() do
    Application.get_env(:ucx_ucc, :ecto_repos)
  end

  def create do
    repos = get_repos()
    Enum.each repos, fn repo ->
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          Logger.info "Created repo #{inspect repo}"
        {:error, :already_up} ->
          Logger.info "Repo #{inspect repo} is already up"
        {:error, term} ->
          Logger.error "Repo #{inspect repo} returned error #{inspect term}"
      end
    end
  end

  def update do
    Ecto.Migrator.run Repo, migrations_path(), :up, all: true
  end

  def drop do
    repos = get_repos()
    Enum.each repos, fn repo ->
      case repo.__adapter__.storage_down(repo.config) do
        :ok ->
          Logger.info "Repo #{inspect repo} closed down"
        {:error, :already_down} ->
          Logger.info "Repo #{inspect repo} is already down"
        {:error, term} ->
          Logger.error "Repo #{inspect repo} returned error #{inspect term}"
      end
    end
  end
end

