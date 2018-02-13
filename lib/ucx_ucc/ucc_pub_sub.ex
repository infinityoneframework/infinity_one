defmodule UcxUcc.UccPubSub do
  @moduledoc """
  A light weight PubSub framework for UcxUcc

  """
  use GenServer

  require Logger

  @name __MODULE__

  defstruct subscriptions: %{}

  defmacro __using__(_) do
    quote do
      use unquote(__MODULE__).Api
      alias unquote(__MODULE__), warn: false
    end
  end

  ################
  # Public API

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end


  def subscribe(topic) do
    subscribe self(), topic
  end

  def subscribe(pid, topic) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, "*", nil}
  end

  def subscribe(topic, event) do
    subscribe self(), topic, event
  end

  def subscribe(pid, topic, event) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, event, nil}
  end

  def subscribe(topic, event, meta) do
    subscribe self(), topic, event, meta
  end

  def subscribe(pid, topic, event, meta) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, event, meta}
  end

  def unsubscribe(pid) when is_pid(pid) do
    GenServer.cast @name, {:unsubscribe, pid}
  end

  def unsubscribe(topic) do
    unsubscribe self(), topic
  end

  def unsubscribe(pid, topic) when is_pid(pid) do
    GenServer.call @name, {:unsubscribe, pid, topic}
  end

  def unsubscribe(topic, event) do
    unsubscribe self(), topic, event
  end

  def unsubscribe(pid, topic, event) when is_pid(pid) do
    GenServer.call @name, {:unsubscribe, pid, topic, event}
  end

  def broadcast(topic, event, payload) do
    GenServer.cast @name, {:broadcast, topic, event, payload}
  end

  def broadcast(topic, event) do
    broadcast topic, event, nil
  end

  def state do
    GenServer.call @name, :state
  end

  ################
  # Callbacks

  def init(_) do
    {:ok, initial_state()}
  end

  def initial_state do
    __MODULE__.__struct__
  end

  def handle_cast({:subscribe, pid, topic, event, meta}, state) do
    subs =
      update_in state.subscriptions, [{topic, event}], fn
        nil -> [{pid, meta}]
        list -> [{pid, meta} | list]
      end
    Process.monitor pid
    {:noreply, struct(state, [subscriptions: subs])}
  end

  def handle_cast({:broadcast, topic, event, payload}, state) do
    Logger.debug "broadcast, topic: #{topic}, event: #{event}"
    # state.subscriptions
    # |> Map.get({topic, "*"}, [])
    # |> broadcast_to_list(topic, event, payload)

    # state.subscriptions
    # |> Map.get({topic, event}, [])
    # |> broadcast_to_list(topic, event, payload)

    state.subscriptions
    |> Enum.filter(fn {{t, e}, _} -> String.match?(topic, ~r/^#{t}/) and (e == "*"
      or String.match?(event, ~r/^#{e}/)) end)
    |> Enum.map(&elem &1, 1)
    |> broadcast_to_list(topic, event, payload)

    {:noreply, state}
  end

  def handle_cast({:unsubscribe, pid}, state) when is_pid(pid) do
    {:noreply, unsubscribe_pid(pid, state)}
  end

  def handle_call({:unsubscribe, _pid, topic}, _, state) do
    subs =
      state.subscriptions
      |> Enum.reject(fn
        {^topic, _} -> true
        _           -> false
      end)
      |> reject_empty_lists
    {:reply, :ok, struct(state, subscriptions: subs)}
  end

  def handle_call({:unsubscribe, _pid, topic, event}, _, state) do
    subs =
      state.subscriptions
      |> Enum.reject(fn
        {^topic, ^event} -> true
        _           -> false
      end)
      |> reject_empty_lists
    {:reply, :ok, struct(state, subscriptions: subs)}
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  def handle_info({:DOWN, _, :process, pid, _reason}, state) do
    # Logger.info "un-subscribing pid: #{inspect pid} for #{inspect reason}"
    {:noreply, unsubscribe_pid(pid, state)}
  end

  def handle_info(event, state) do
    Logger.error "unrecognized event: #{inspect event}"
    {:noreply, state}
  end

  ################
  # Private

  def unsubscribe_pid(pid, state) do
    subs =
      for {key, values} <- state.subscriptions do
        new_list =
          Enum.reject values, fn
            {^pid, _} -> true
            _         -> false
          end
        {key, new_list}
      end
      |> reject_empty_lists
    struct state, subscriptions: subs
  end

  defp reject_empty_lists(subscriptions) do
    subscriptions
    |> Enum.reject(fn
        {_, []} -> true
        _ -> false
    end)
    |> Enum.into(%{})
  end

  defp broadcast_to_list(lists, topic, event, payload) do
    Enum.each lists, fn list ->
      Enum.each(list, fn
        {pid, nil} ->
          # Logger.debug "sending to #{inspect pid}, #{inspect {topic, event, payload}}"
          spawn fn -> send pid, {topic, event, payload} end
        {pid, meta} ->
          # Logger.debug "sending to #{inspect pid}, #{inspect {topic, event, payload, meta}}"
          spawn fn -> send pid, {topic, event, payload, meta} end
      end)
    end
  end
end
