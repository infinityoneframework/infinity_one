defmodule OnePages.Github.Server do
  @moduledoc """
  Throttle interactions with the Github API.

  Get the latest tag information from Github upon startup. Cache the result in
  its internal state.

  When a request for the latest tag information is received by the `get/0` API,
  return the cached result if it has already been fetched within the configured
  `:github_poll_timeout` timeout (in seconds).

  If the data is older than the `:github_poll_timeout`, then block the caller and
  start start a fetch from Github.

  Upon receipt of the response from Github, insert_or_update the version database
  and update the server's state. The new or updated version record is returned back
  to each blocked caller.

  If the request is not received back from Github with 5 seconds, each caller receives
  a `{:error, :timeout}` tuple.

  In the event of a timeout, the caller has the option of failing, or calling the
  `git_last/0` API to fetch the last result. This will either be a version schema
  or nil.

  The server does an initial fetch 1 second after startup.
  """
  use GenServer

  alias OnePages.{Github, Version}

  require Logger

  @name __MODULE__
  @default_poll_timeout 60 * 60 # 1 hour
  @env Mix.env()

  ##############
  ## Public API

  @doc """
  Start the GenServer
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Get the latest version schema.

  If the cached version is less than `:github_poll_timeout` seconds old,
  return it. Otherwise, block while the data is pulled from Github and the database
  is updated.

  Returns either:
  * {:ok, version}
  * {:error, :timeout}
  """
  def get do
    check_and_sync(self())
    receive do
      {:github_sync_done, version} -> {:ok, version}
      other ->
        Logger.error "unexpected result: " <> inspect(other)
    after
      5_000 -> {:error, :timeout}
    end
  end

  @doc """
  Get the last fetched version schema from the server.

  Return the server's cached value without checking for its age or attempting to
  fetch an updated version.

  Returns either a `%OnePages.Schema.Version{}` schema or nil.
  """
  def get_last do
    GenServer.call(@name, :get_last)
  end

  ##############
  ## Callbacks

  def init(_) do
    timeout = Application.get_env(:one_pages, :github_poll_timer, @default_poll_timeout)
    unless @env == :test do
      Process.send_after @name, :poll_github, 1_000
    end
    {:ok, %{version: nil, pending: [], last_polled: nil, poll_timeout: timeout}}
  end

  def handle_cast({:check_and_sync, caller}, state) do
    now = NaiveDateTime.utc_now()
    state =
      cond do
        is_nil(state.version) and state.pending == [] ->
          spawn_poll_github()
          update_in(state, [:pending], & [caller | &1])

        is_nil(state.version) ->
          update_in(state, [:pending], & [caller | &1])

        NaiveDateTime.diff(now, state.last_polled) <= state.poll_timeout ->
          send caller, {:github_sync_done, state.version}
          state

        state.pending == [] ->
          # first one to request after timeout, so start the poll
          spawn_poll_github()
          update_in(state, [:pending], & [caller | &1])

        true ->
          update_in(state, [:pending], & [caller | &1])
      end
    {:noreply, state}
  end

  def handle_call(:get_last, _, state) do
    {:reply, state.version, state}
  end

  def handle_info(:poll_github, state) do
    Logger.debug "polling github..."
    state =
      if state.pending == [] do
        spawn_poll_github()
        self = self()
        update_in(state, [:pending], & [self | &1])
      else
        state
      end

    {:noreply, state}
  end

  def handle_info({:poll_results, results}, state) do
    state =
      case Version.insert_or_update(results) do
        {:ok, version} ->
          now = NaiveDateTime.utc_now()
          state
          |> Map.put(:last_polled, now)
          |> Map.put(:version, version)
        {:error, changeset} ->
          Logger.error("Version.insert_or_update error: " <> inspect(changeset.errors))
          state
      end

    Enum.each(state.pending, & send(&1, {:github_sync_done, state.version}))
    {:noreply, Map.put(state, :pending, [])}
  end

  def handle_info({:github_sync_done, version}, state) do
    {:noreply, Map.put(state, :version, version)}
  end

  ##############
  ## Private

  defp spawn_poll_github do
    spawn fn ->
      results = Github.latest()
      send(@name, {:poll_results, results})
    end
  end

  defp check_and_sync(caller) do
    GenServer.cast(@name, {:check_and_sync, caller})
  end

  # # For testing purposes
  # def run do
  #   spawn fn ->
  #     IO.inspect self(), label: "starting process"
  #     case get() do
  #       {:ok, version} ->
  #         IO.inspect {self(), version.name, version.assets |> length}, label: "process done"
  #       {:error, :timeout} ->
  #         IO.inspect {self(), :timeout}, label: "process done"
  #     end
  #   end
  # end
end
