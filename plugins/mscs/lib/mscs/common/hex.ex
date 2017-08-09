# Copyright (C) E-MetroTel, 2015 - All Rights Reserved 
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of 
# a written license agreement with E-MetroTel.

defmodule Mscs.Hex do

  use Bitwise

  def h2s(item, padding \\ [], prefix \\ '') do
    _hex_to_str(item, padding, prefix)
  end
  defp _hex_to_str([], _padding, _prefix) do
    "[]"
  end
  defp _hex_to_str(item, padding, prefix) when is_binary(item) do
    _hex_to_str :erlang.binary_to_list(item), padding, prefix
  end
  defp _hex_to_str(item, padding, prefix) when is_list(item) do
    item |> list_to_hex(prefix, padding) |> hex_list_to_str
  end
  defp _hex_to_str(item, prefix, padding) when is_number(item) do
    item |> int_to_hex(prefix, padding)
  end

  def hex_list_to_str(list) do
    [_|tail] = Enum.reduce list, '', fn(x,acc) ->
      acc ++ ' ' ++ x
    end
    tail
  end

  def list_to_hex(list, prefix \\ '', padding \\ []) do
    Enum.map list, &(int_to_hex(&1, prefix, padding))
  end


  def int_to_hex(n, prefix \\ '', padding \\ []) do
    _int_to_hex(n, padding, prefix)
  end
  defp _int_to_hex(n, prefix, padding) when n > 0x2ffff do
    _int_to_hex(n &&& 0xffff, prefix, padding)
  end
  defp _int_to_hex(n, prefix, _padding) when n > 0xff and n < 0x1ffff do
    nh = n >>> 8
    nl = n &&& 0xff
    prefix ++ [hex(div(nh,16)), hex(rem(nh,16)),hex(div(nl, 16)), hex(rem(nl, 16))]
  end
  defp _int_to_hex(n, prefix, padding) when n < 0x100 do
    prefix ++ padding ++ [hex(div(n, 16)), hex(rem(n, 16))]
  end

  def hex(n) when n < 10 do
    0x30 + n
  end
  def hex(n) when n >= 10 and n < 16 do
    0x61 + (n - 10)
  end

end
