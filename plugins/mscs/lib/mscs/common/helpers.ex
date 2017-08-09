defmodule Mscs.Helpers do
  use Bitwise

  def to_integer({a, b, c, d}) do
    (a <<< 24) + (b <<< 16) + (c <<< 8) + d
  end

  def to_integer([a, b, c, d]), do: to_integer({a, b, c, d})
  def to_integer([]), do: 0

  def list_to_integer(list, count) do
    range = (count - 1)..0
    Enum.zip(range, list) |>
      Enum.reduce(0, fn(v,acc) ->
        {sh, item} = v
        acc ||| (item <<< (sh * 8))
      end )
  end
  def list_to_integer(list) do
    list_to_integer list, length(list)
  end

  def integer_to_list(num, byte_size) do
    (byte_size - 1)..0 |> Enum.map(&((num >>> (&1 * 8)) &&& 0xff))
  end

end
