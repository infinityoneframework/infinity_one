defmodule Mscs.SystemAgent do
  @moduledoc """
  State persistence for system wide data.

  This is a structure and a wrapper around an Agent for persisting
  run time system level information.

  A simple API provides functions to access data in the structure.

  * `get/0` - Get the full state struct
  * `get/1` - Get a specific field in the state struct
  * `get/2` - Get a specific map entry from a field in the state struct
  * `put/2` - Replace the field in the state structure
  * `put/3` - Replace a map entry for a field in the state struct
  * `update/1` - Update the complete state struct
  * `update/2` - Update a field in the state struct
  * `clear/0` - Reset the state struct back to its defaults
  * `size/1` - Get the count of a field in the state struct
  * `delete/2` - Remove a field item from the state struct
  """
  require Logger

  defstruct clients: %{}, extensions: %{},
            licensed: [], unlicensed: [], free_ports: [],
            recovering: %{}

  def new, do: %__MODULE__{}
  def new(opts), do: struct(new, opts)

  def start_link do
    Agent.start_link(fn -> new end, name: __MODULE__)
  end

  def get do
    Agent.get __MODULE__, fn(state) -> state end
  end

  def get(key) do
    Agent.get __MODULE__, fn(state) -> Map.get state, key end
  end

  def get(key, index) do
    Agent.get __MODULE__, fn(state) ->
      try do
        Map.get(state, key) |> _get(index)
      rescue
        err ->
          Logger.error "Exception #{inspect err}"
          state
      end
    end
  end

  def _get(field, index) when is_map(field) do
    Map.get field, index
  end
  def _get(field, index) when is_list(field) do
    Enum.find field, &(&1 == index)
  end

  def put(key, data) do
    Agent.cast __MODULE__, fn(state) -> Map.put state, key, data end
  end

  def put(key, index, data) do
    Agent.cast __MODULE__, fn(state) ->
      try do
        item = Map.get state, key
        Map.put state, key, _put(item, index, data)
      rescue
        err ->
          Logger.error "Exception #{inspect err}"
          state
      end
    end
  end

  def push(key, value) do
    Agent.cast __MODULE__, fn(state) ->
      try do
        Map.put state, key, [value | Map.get(state, key)]
      rescue
        err ->
          Logger.error "Exception #{inspect err}"
          state
      end
    end
  end

  defp _put(field, index, data) when is_map(field) do
    Map.put(field, index, data)
  end

  def update(key, fun) do
    Agent.cast __MODULE__, fn(state) ->
      try do
        Map.put state, key, fun.(Map.get(state, key))
      rescue
        err ->
          Logger.error "Exception #{inspect err}"
          state
      end
    end
  end

  def update(fun) do
    Agent.cast __MODULE__, fun
  end

  def size(key) do
    get(key) |> length
  end

  def clear do
    Agent.cast __MODULE__, fn(_) -> __MODULE__.new end
  end

  def delete(key, index) do
    Agent.cast __MODULE__, fn(state) ->
      try do
        Map.put(state, key, _delete(Map.get(state, key), index))
      rescue
        err ->
          Logger.error "Exception: #{inspect err}"
          state
      end
    end
  end

  defp _delete(field, value) when is_map(field) do
    Map.delete field, value
  end
  defp _delete(field, value) when is_list(field) do
    Enum.filter field, &(&1 != value)
  end

end
