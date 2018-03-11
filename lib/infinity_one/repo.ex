defmodule InfinityOne.Repo do
  use Ecto.Repo, otp_app: :infinity_one
  use Scrivener, page_size: 120, options: [from_bottom: true]

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
