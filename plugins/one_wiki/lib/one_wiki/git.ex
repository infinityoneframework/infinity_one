defmodule OneWiki.Git do
  @moduledoc """
  Interface with the GitCli dependency.
  """
  use Timex

  require Logger
  @doc """
  The path the the pages repo.
  """
  def path, do: OneWiki.pages_path()

  @doc """
  Create a new repo instance.
  """
  def repo, do: Git.new(path())

  @doc """
  Perform a git commit.

  Returns:
  * {:ok, result}
  * {:error, error}
  """
  def commit(message, user, repo \\ repo()) do
    Git.commit(repo, ["-m", message, ~s/--author="@#{user.username}<#{user.email}>"/])
  end

  @doc """
  Perform a git commit.

  Returns:
  * result if successful
  * raises runtime exception on failure
  """
  def commit!(message, user, repo \\ repo()) do
    case commit(message, user, repo) do
      {:ok, result} -> result
      {:error, error} -> raise("git commit error #{inspect error}")
    end
  end

  @doc """
  Run git show on commit and file.
  """
  def show(commit, title) do
    case Git.show repo(), commit <> ":" <> title do
      {:ok, contents} -> contents
      {:error, error} -> error
    end
  end

  def show(commit) do
    repo = repo()
    with {:ok, show} <- Git.show(repo, ["--name-only", commit]),
         [_, title] <- Regex.run(~r/([^\n]+)\n$/, show) do
      {title, show(commit, title)}
    else
      {:error, error} -> error
      nil -> {:error, "Could not find the title."}
    end
  end

  @doc """
  Perform a git log on a specific file.

  ## Options

  * parse: <true|false> - (true) When true, parses the output and returns an
    array of maps for each commit
  """
  def log(title, opts \\ []) do
    repo = opts[:repo] || repo()
    parse = Keyword.get(opts, :parse, true)
    repo
    |> Git.log(["--follow", "--abbrev-commit", title])
    |> parse_log(parse)
  end

  @doc """
  Parse the results of the git log command.
  """
  def parse_log({:ok, result}, true) do
    result
    |> String.split("\n", trim: true)
    |> parse_log_entries()
  end

  def parse_log(result, false) do
    result
  end

  def parse_log({:error, error}, _) do
    {:error, error}
  end

  defp parse_log_entries(list) do
    list
    |> Enum.reduce([], fn
      "commit " <> hash, acc ->
        [%{commit: hash} | acc]
      "Author: " <> author, [map | acc] ->
        [Map.put(map, :author, author) | acc]
      "Date:" <> date, [map | acc] ->
        date = String.trim(date)
        datetime =
          case parse_date(date) do
            {:ok, dt} -> dt
            _ -> date
          end
        [Map.put(map, :date, datetime) | acc]
      commit_message, [map | acc] ->
        [Map.put(map, :message, String.trim(commit_message)) | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Converts the date field into a NaiveDatetime struct.

  ## Examples

      iex> OneWiki.Git.parse_date("Wed Apr 11 20:23:05 2018 -0400")
      ~N[2018-04-12 00:23:05]
  """
  def parse_date(string) do
    case Timex.parse(string, "%a %b %d %H:%M:%S %Y %Z", :strftime) do
      {:ok, datetime} ->
        Timex.to_naive_datetime datetime
      error ->
        error
    end
  end
end
