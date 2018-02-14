defmodule UccChat.PresenceAgent do
  @moduledoc """
  Handles presence status for use with views.

  This module works in conjunction with Phoenix.Presence to manage presence
  state for the application.

  While the channel presence is responsible for notifying of state changes,
  this module provides this state to the controllers and views. Furthermore,
  state overrides are handled her.

  """
  use GenServer
  import Ecto.Query

  alias UcxUcc.{Repo}
  alias UcxUcc.Accounts.User

  require Logger

  @name __MODULE__
  # @audit_secs 120

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
    # Agent.start_link(fn -> %{} end, name: @name)
  end

  @doc """
  Load a user's status.

  Called in a number of scenarios
    * User logs in
    * User reloads browser

  Reads the User's status form the database. If set, uses that as
  an override. Otherwise, sets the status to "online"
  """
  def load(user_id) when is_binary(user_id) do
    GenServer.cast @name, {:load, user_id}
  end

  @doc """
  Logs a user out by clearing their entry in the status list.
  """
  # def unload(user_id) when is_integer(user_id) do
  #   user_id |> to_string |> unload
  # end
  def unload(user) do
    GenServer.cast @name, {:unload, user}
  end

  # def update_presence(user_id, status) when is_integer(user_id),
  #   do: user_id |> to_string |> update_presence(status)

  def update_presence(user, status) do
    GenServer.cast @name, {:update_presence, user, status}
  end

  # def get_and_update_presence(user_id, status) when is_integer(user_id),
  #   do: user_id |> to_string |> get_and_update_presence(status)

  def get_and_update_presence(user, status) do
    GenServer.call @name, {:get_and_update_presence, user, status}
  end
  # Agent.get_and_update name, &(get_and_update_in(&1, ["18"], fn state -> {"busy", "busy"} end))

  @doc """
  Change user status.

  Called when the user selects a status from the side nav. Status is
  stored in the database unless its "online", where its removed from
  the database.
  """
  # def put(user_id, status) when is_integer(user_id) do
  #   user = to_string user_id
  #   put(user_id, user, status)
  # end
  def put(user_id, status) when is_binary(user_id) do
    put(user_id, user_id, status)
  end

  def put(user_id, user, "online") do
    GenServer.cast @name, {:put, user_id, user, "online"}
  end

  def put(user_id, user, "invisible") do
    put(user_id, user, "offline")
  end

  def put(user_id, user, status) do
    GenServer.cast @name, {:put, user_id, user, status}
  end

  # def get(user_id) when is_integer(user_id),
  #   do: user_id |> to_string |> get

  def get(user) do
    GenServer.call @name, {:get, user}
  end

  # def active?(user_id) when is_integer(user_id),
  #   do: user_id |> to_string |> active?

  def active?(user) do
    GenServer.call @name, {:active?, user}
  end

  def all do
    GenServer.call @name, :all
  end

  def clear do
    GenServer.cast @name, :clear
  end

  def init(_) do
    {:ok, %{}}
  end

  ##############
  # casts

  def handle_cast(:clear, _data) do
    noreply initial_state()
  end

  def handle_cast({:put, user_id, user, "online"}, data) do
    set_chat_status(user_id, nil)
    data
    |> Map.put(user, "online")
    |> noreply
  end

  def handle_cast({:put, user_id, user, status}, data) do
    set_chat_status(user_id, status)
    data
    |> Map.put(user, {:override, status})
    |> noreply
  end

  def handle_cast({:update_presence, user, status}, data) do
    update_in data, [user], fn
      {:override, _} = override -> override   # don't change the override
      _ -> status                            # new status
    end
    |> noreply
  end

  def handle_cast({:unload, user}, data) do
    data
    |> Map.delete(user)
    |> noreply
  end

  def handle_cast({:load, user_id}, data) do

    query =
      from u in User,
        where: u.id == ^user_id,
        select: u.chat_status

    status =
      query
      |> Repo.one
      |> case do
        nil    -> "online"
        ""     -> "online"
        status -> {:override, status}
      end

    data
    |> Map.put(to_string(user_id), status)
    |> noreply
  end

  ##############
  # calls

  def handle_call(:all, _, data) do
    reply data, data
  end

  def handle_call({:active?, user}, _, data) do
    reply data, not is_nil(Map.get(data, user))
  end

  def handle_call({:get, user}, _, data) do
    reply =
      case Map.get(data, user) do
        {:override, status} -> status
        nil -> "offline"
        status -> status
      end

    reply data, reply
  end

  def handle_call({:get_and_update_presence, user, status}, _, data) do
    {reply, data} =
      get_and_update_in data, [user], fn
        {:override, val} = override -> {val, override}   # don't change the override
        _ -> {status, status}                            # new status
      end
    reply data, reply
  end

  ##############
  # infos

  def handle_info(_, data) do
    noreply data
  end


  ##################
  # Private

  def initial_state, do: %{}

  defp user(user_id) do
    Repo.one!(from u in User, where: u.id == ^user_id)
  end

  defp set_chat_status(user_id, status) do
    user_id
    |> user
    |> User.changeset(%{chat_status: status})
    |> Repo.update
  end

  defp noreply(data), do: {:noreply, data}
  defp reply(data, reply), do: {:reply, reply, data}

end
