defmodule UcxUcc.Mix do
# use Ecto.Adapter.Storage
  alias UcxUcc.Repo

  def migrations_path() do
    Path.join [Application.app_dir(:ucx_ucc) | ~w(priv repo migrations)]
  end

  def create do
    #Ecto.Adapter.Storage.storage_up Repo
    Ecto.Storage.up Repo
  end

  def update do
    Ecto.Migrator.run Repo, migrations_path(), :up, all: true
  end

  def drop do
    #Ecto.Adapter.Storage.storage_down Repo
    Ecto.Storage.down Repo
  end
end

