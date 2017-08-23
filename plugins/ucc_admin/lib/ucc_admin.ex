defmodule UccAdmin do
  @name :admin_pages

  def initialize do
    :ets.new @name, [:public, :named_table]
  end

  def add_page(page) do
    insert page.id, page
  end

  def get_page(id) do
    case lookup id do
      [{_, data}] -> data
      _ -> nil
    end
  end

  def get_pages do
    @name
    |> :ets.match({:"_", :"$2"})
    |> List.flatten
    |> Enum.sort(& &1.order < &2.order)
  end

  defp insert(key, value) do
    :ets.insert @name, {key, value}
  end

  defp lookup(key) do
    :ets.lookup @name, key
  end

end
