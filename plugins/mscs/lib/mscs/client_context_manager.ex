defmodule Mscs.ClientContextManager do
  @moduledoc """
  Saves ClientSm Context for reloading in case of a ClientSm crash.

  This server saves the ClientSm's state for later retrieval if 
  the sm crashes. This ensures that the process can be restarted 
  with the last known state before it crashed.
  """
  @name :client_state_manager

  @doc """
  Start the agent
  """
  def start_link do
    Agent.start_link fn -> HashDict.new end, name: @name
  end

  @doc """
  Save the context.
  """
  def put(cx, state_name) do
    Agent.update @name, fn(x) -> 
      Dict.put(x, cx.mac, %{cx: cx, state: state_name})
    end
    cx
  end
  def put(cx) do
    Agent.update @name, fn(x) -> 
      Dict.put(x, cx.mac, %{Dict.get(x, cx.mac) | cx: cx})
    end
    cx
  end

  @doc """
  Get all the state in the agent
  """
  def get() do
    Agent.get @name, fn(x) -> x end
  end

  def get(mac) when is_binary(mac) do
    Agent.get @name, fn(x) -> 
      Dict.get(x, mac)
    end
  end
  def get(cx) do
    Agent.get @name, fn(x) -> 
      Dict.get(x, cx.mac)
    end
  end

  @doc """
  Clear the state
  """
  def clear do
    Agent.update @name, fn(_) -> HashDict.new end
  end
  def delete(mac) when is_binary(mac) do
    Agent.update @name, fn(x) -> Dict.delete(x, mac) end
  end
  def delete(cx) do
    Agent.update @name, fn(x) -> Dict.delete(x, cx.mac) end
  end
  
end
