defmodule OneChatWeb.RoomChannel.KeyStore do

  @name :key_store

  def initialize do
    :ets.new @name, [:public, :named_table]
  end

  def put(id, value) do
    :ets.insert @name, {id, value}
  end

  def get do
    :ets.match @name, :"$1"
  end

  def get(id) do
    case :ets.match(@name, {id, :"$1"}) do
      [[value]] -> value
      _ -> nil
    end
  end

  def delete(id) do
    :ets.delete @name, id
  end

  def reset do
    :ets.match_delete @name, :"$1"
  end
end
