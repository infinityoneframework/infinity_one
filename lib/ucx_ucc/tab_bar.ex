defmodule UcxUcc.TabBar do
  @name :tabbar

  def initialize do
    :ets.new @name, [:public, :named_table]
  end

  def insert(key, value) do
    :ets.insert @name, {key, value}
  end

  def lookup(key) do
    :ets.lookup @name, key
  end

  def add_button(config) do
    insert config.id, config
  end

  def get_button(key) do
    case lookup key do
      [{_, data}] -> data
      _ -> nil
    end
  end

  def get_button!(key) do
    get_button(key) || raise("invalid button #{key}")
  end

  def get_buttons() do
    :ets.match(@name, :"$1")
    |> List.flatten
    |> Keyword.values
    |> Enum.sort(& &1[:order] < &2[:order])
  end
end
