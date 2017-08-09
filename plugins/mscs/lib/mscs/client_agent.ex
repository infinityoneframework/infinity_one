defmodule Mscs.ClientAgent do
  require Logger

  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
  end

  def get do
    Agent.get __MODULE__, fn(state) -> state end
  end
  
  def get(mac) do
    Agent.get __MODULE__, fn(state) -> Dict.get state, mac end
  end

  def put(mac, pid) do
    Agent.cast __MODULE__, fn(state) -> Dict.put state, mac, pid end
  end

  def clear do
    Agent.cast __MODULE__, fn(_) -> HashDict.new end
  end

  def delete(mac) do
    Agent.cast __MODULE__, fn(state) -> Dict.delete state, mac end
  end

end
