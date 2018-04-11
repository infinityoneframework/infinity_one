defmodule OneWiki do
  @moduledoc """
  A Static Pages plug-in for InfinityOne
  """

  @doc """
  Get the path to the pages folder
  """
  def pages_path do
    path = "priv/static/uploads/pages"
    if InfinityOne.env == :prod do
      Path.join(Application.app_dir(:infinity_one), path)
    else
      path
    end
  end

  @doc """
  Create the pages file storage directory if it does not already exist
  """
  def create_pages_path do
    path = pages_path()
    unless File.exists?(path) do
      File.mkdir_p(path)
    end
  end

  @doc """
  Initialize the git repo if it is not already initialized
  """
  def initialize_git do
    path = Path.join(pages_path(), ".git")
    unless File.exists?(path) do
      Git.init(pages_path())
    end
  end

  @doc """
  Initialize the pages file store
  """
  def initialize do
    create_pages_path()
    initialize_git()
  end
end
