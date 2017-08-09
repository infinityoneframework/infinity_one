# Copyright (C) E-MetroTel, 2015 - All Rights Reserved
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of
# a written license agreement with E-MetroTel.


defmodule Tn do
  use Bitwise

  @max_units 16
  @max_units_dsp 32
  @max_cards 10
  @max_shelves 2
  @max_loops 256

  def pack(l,c,u) do
    (l <<< 8) ||| (c <<< 2) ||| u
  end
  def pack(l, _s, c, u, density) when density == :single do
    pack(l,c,u)
  end
  def pack(l, s, c, u, density) when density == :double do
    pack l, s, c, u
  end
  def pack(l, s, c, u, density) when density == :quad do
    pack l, s, c, u
  end
  def pack(l, s, c, u, density) when density == :octal do
    pack l, s, c, u
  end

  def pack(l,s,c,u) when s >= 0 and s < 2 and u >= 0 and u < 32
                         and (l &&& 0x3) == 0 and c >= 0 and c < 16 do
    ((l &&& 0xfc) <<< 8) ||| (s <<< 9) ||| (c <<< 2) ||| (((u &&& 0x1f) >>> 2) <<< 6) ||| (u &&& 3)
  end
  def pack(tn) when is_number(tn), do: tn
  def pack(tn) when is_binary(tn) do
    <<num::16>> = tn
    num
  end
  def pack({l,c,u}), do: pack(l,c,u)
  def pack({l,s,c,u}), do: pack(l,s,c,u)

  def get_card_bits(tn), do: (tn &&& 0x003c)
  def pack_card_bits_unit(cbits, u), do: cbits ||| (u &&& 3) ||| ((u &&& 0xc) <<< 4)

  # handle the dtr case
  def pack_dtr({l,s,c,u}), do: pack_dtr(l,s,c,u)
  def pack_dtr(l,s,c,u) when (c == 0 or c == 14 or c == 15) and (u >= 0 and u < 8) do
    ((l &&& 0xfc) <<< 8) ||| (s <<< 9) ||| (c <<< 2) ||| (u <<< 6)
  end

  def unpack(num) when is_binary(num) do
    <<l::6,s::1,uh::3,c::4,ul::2>> = num
    unpack(l, s, c, uh, ul)
  end
  def unpack(tn) when is_tuple(tn), do: tn
  def unpack(tn) when is_integer(tn), do: unpack(<<tn::16>>)

  def unpack(l, s, c, uh, ul) do
    { l * 4 , s, c, uh * 4 + ul}
  end

  def dtr_to_tn(dtr_tn) do
    Tn.unpack_dtr(dtr_tn)
    |> Tn.pack
  end

  def tn_to_dtr(tn) do
    Tn.unpack(tn)
    |> Tn.pack_dtr
  end

  def loop_dtr(tn) do
    Tn.unpack_dtr(tn)
  end

  def loopsh_dtr(tn) do
    (tn >>> 8) &&& 0x3f
  end

  def cardunit_dtr(tn) do
    (tn &&& 0xfc)
  end

  # handle the dtr case
  def unpack_dtr(tn) when is_integer(tn), do: unpack_dtr(<<tn::16>>)
  def unpack_dtr(num) when is_binary(num) do
    <<l::6,s::1,uh::3,c::4,_ul::2>> = num
    unpack_dtr(l, s, c, uh)
  end
  def unpack_dtr(l, s, c, uh) when c == 0 or c == 14 or c == 15 do
    {l * 4, s, c, uh}
  end

  def unpack_loopsh(tn) do
    {l, s, _c, _u} = unpack(tn)
    l + (s <<< 1)
  end

  def loopsh(tn) do
    unpack_loopsh(tn)
  end
  def loopsh(loop, shelf) do
    loop ||| (shelf <<< 1)
  end
  def loop(tn) do
    {l, _s, _c, _u} = unpack(tn)
    l
  end

  def loop(tn, density) when density == :single do
    tn >>> 8
  end

  def shelf(tn) do
    {_l, s, _c, _u} = unpack(tn)
    s
  end
  def card(tn) do
    {_l, _s, c, _u} = unpack(tn)
    c
  end
  def unit(tn) do
    {_l, _s, _c, u} = unpack(tn)
    u
  end
  def unit(tn, density) when density == :single do
    tn &&& 0x3
  end
  def card_unit(tn) do
    tn &&& 0x1ff
  end

  def cabinet(tn) do
    {l, s, _c, _u} = unpack(tn)
    cabinet_from_loop_shelf(l,s)
  end
  def cabinet(loop, shelf) do
    cabinet_from_loop_shelf loop, shelf
  end
  def cabinet_from_loop_shelf(loop, shelf) do
    (loop >>> 1) + shelf + 1
  end
  def cabinet_to_loop_shelf(cabinet) when cabinet > 0 do
    cab = cabinet - 1
    {(cab &&& 0xfe) <<< 1, cab &&& 1}
  end

  def cabinet_to_loopsh(cab), do: (2 * cab) - 2

  # this function is to include card 0
  def to_index_0(tn) do
    {l, s, c, u} = unpack(tn)
    to_index_0 l, s, c, u
  end
  def to_index_0(l, s, c, u)  do
    (((l >>> 1) &&& 0xfe) + s) * (@max_units_dsp * 16) + (c * @max_units_dsp) + u
  end

  def to_index(tn) do
    {l, s, c, u} = unpack(tn)
    to_index l, s, c, u
  end

  def to_index(l, s, c, u) when u >= 0 and u < @max_units and
                                c >= 0 and c <= @max_cards and
                                s >= 0 and s < @max_shelves and
                                l >= 0 and l < @max_loops do
    (((l >>> 1) &&& 0xfe) + s) * (@max_units * @max_cards) + ((c - 1) * @max_units) + u
  end

  def from_index(index) do
    loop_sh = div(index, @max_units * @max_cards)
    cards_units = rem(index, @max_units * @max_cards)
    card = div(cards_units, @max_units)
    unit = rem(cards_units, @max_units)
    loop = (loop_sh &&& 0xfe) <<< 1
    sh = (loop_sh &&& 1)
    Tn.pack(loop, sh, card + 1, unit)
  end

  def to_ssd0_out(tn), do: ((tn &&& 0xff00) >>> 8) ||| 0xc000
  def to_ssd1_out(tn), do: (tn &&& 0xff) <<< 4
  def to_ssds_out(tn), do: {to_ssd0_out(tn), to_ssd1_out(tn)}

  def to_ssd0_in(tn), do: ((tn &&& 0xff00) >>> 8)
  def to_ssd1_in(tn), do: tn &&& 0x00ff
  def to_ssds_in(tn), do: {to_ssd0_in(tn), to_ssd1_in(tn)}
  def to_ssds_in(tn, ssd2), do: {to_ssd0_in(tn), to_ssd1_in(tn), ssd2}

  def from_ssd_in(ssd0, ssd1) do
    ((ssd0 &&& 0xff) <<< 8) ||| (ssd1 &&& 0xff)
  end
  def tn_desc(cx) when is_map(cx), do: {cx.ssd_server, cx.tn}
  def tn_desc(tn, receiver \\ self), do: {:tn_desc, tn, receiver}


  def inspect(tn) do
    {l,s,c,u} = Tn.unpack(tn)
    "(#{inspect tn, base: :hex}) #{l}-#{s}-#{c}-#{u}"
  end

  def log_format(tn), do: "Tn: (#{inspect tn, base: :hex})"
  def log_format(tn, :long), do: "Tn: #{Tn.inspect(tn)}"
end
