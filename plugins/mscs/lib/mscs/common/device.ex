# # Copyright (C) E-MetroTel, 2015 - All Rights Reserved
# # This software contains material which is proprietary and confidential
# # to E-MetroTel and is made available solely pursuant to the terms of
# # a written license agreement with E-MetroTel.


# defmodule Mscs.Device do

#   use Bitwise
#   require Logger

#   import Mscs.DeviceConstants


#   defmodule DeviceProperties do
#     defstruct [:program_keys, :soft_keys, :consp_keys, :nav_keys,
#                :headset, :mute, :quit, :copy, :mwi, :handsfree,
#                :display_width, :display_lines, :soft_label_size, :date_width]

#     def keys(r) do
#       keys = {r.headset, r.mute, r.quit, r.copy, r.mwi}
#       0..4 |> Enum.to_list |> List.foldl(0, &((elem(keys,&1) <<< &1 )||| &2))
#     end
#     defp get_key(val, pos), do: (val >>> pos) &&& 1
#     def set(r, {pk, sk, ck, nk, keys, hf, dw, dl, sls, daw}) do
#       struct(r, program_keys: pk, soft_keys: sk, consp_keys: ck, nav_keys: nk,
#         headset: get_key(keys, 0), mute: get_key(keys,1), quit: get_key(keys,2),
#         copy: get_key(keys,3), mwi: get_key(keys,4), handsfree: hf, display_width: dw,
#         display_lines: dl, soft_label_size: sls, date_width: daw)
#     end
#   end

#   def device_properties do
#     [
#       #               keys(msb..lsb) (mwi copy quit mute hs)
#       # type            pk sk ck nk  keys  hf dw dl sls daw
#       { unknown_type, { 0,  0, 0, 0,    0, 0,  0, 0, 0,  0}},
# #     IT type 20 phase 6 (6 prog. keys, 3 display lines, date 1) state 2
#       { msc,        { 6,  4, 5, 4, 0x18, 1, 24, 3, 0,  0}}
#     ] |> Enum.into(HashDict.new)
#   end

#   def device_type_map do
#     [
#       { unknown_type, "UNKNOWN" },
#       { msc, "MSC" }
#     ]
#   end
#   def device_type_map(type) when is_number(type) do
#     Logger.debug "Device.device_type_map(number): #{inspect(type)}"
#     case device_type_map |> List.keyfind(type, 0) do
#       nil      -> nil
#       {_, name} -> name
#     end
#   end
#   def device_type_map(name) when is_binary(name) do
#     Logger.debug "Device.device_type_map(binary): #{inspect(name)}"
#     case device_type_map |> List.keyfind(name, 1) do
#       nil      -> nil
#       {num, _} -> num
#     end
#   end
#   def device_type_map(name) when is_list(name) do
#     Logger.debug "Device.device_type_map(list): #{inspect(name)}"
#     device_type_map IO.chardata_to_string(name)
#   end

#   # TODO: this is not very efficient. need to refactor to do a simple list lookup
#   def get_device_properties(device_type, num_keys \\ nil) do
#     num = if num_keys, do: num_keys, else: Mscs.Client.num_keys_default
#     prop = device_properties |> HashDict.get(device_type)
#     Logger.debug "Device.get_device_properties: device_type: #{device_type}, prop: #{inspect(prop)}"
#     properties = %DeviceProperties{}
#     |> DeviceProperties.set(prop)
#     %DeviceProperties{properties | program_keys: num}
#   end

# end


# defmodule Mscs.DeviceData do
#   use Bitwise

#   defstruct number_keys: 0, keys: [], num_digit_keys: 0, digits_list: []

#   @unregistered_keys_adv_display [29, 0 | (for _key <- 1..29,  do: 0xe)]
#   @unregistered_keys_m3202       [7, 0  | (for _key <- 1..7,  do: 0xe)]
#   @unregistered_keys_m3201       [1, 0, 0xe]
#   @unregistered_keys_other       [1, 0, 0xe]

#   def new, do: %Mscs.DeviceData{}
#   def new(opts), do: struct(new, opts)

#   def set(r, key_list) do
#     [num_keys, start_key | tail] = key_list

#     keys = list_fill!(r.keys, 14, start_key) ++ Enum.take(tail, num_keys)
#     # prepare the digits_list directly from the tail end of the key_list when start_key is 0
#     digits_list_from_tail = get_digits_list(Enum.drop(tail, num_keys))
#     digits_list = if start_key != 0, do:
#       merge_digits_list(r.digits_list, digits_list_from_tail),
#     else: digits_list_from_tail
#     num_digit_keys = Enum.count digits_list

#     struct(r, number_keys:  num_keys + start_key, keys: keys,
#       num_digit_keys: num_digit_keys, digits_list: digits_list)
#   end

#   # Merges list2 into list1 and returns merged list
#   defp merge_digits_list(list1, list2) do
#    dict1 = Enum.into list1, HashDict.new
#    dict2 = Enum.into list2, HashDict.new
#    Dict.merge(dict1, dict2)
#    |> Dict.to_list
#    |> Enum.sort(&(elem(&1,0) < elem(&2,0)))

#   end

#   def extension(r) do
#     case Enum.take(r.digits_list, 1) do
#       [] -> []
#       [{_, result}]  -> result
#     end
#   end

#   def dn_int(r) do
#     IO.chardata_to_string(extension(r)) |> Integer.parse |> elem(0)
#   end

#   @doc """
#   Finds the first key number for the given feature code


#   Returns key number if the feature is found
#           nil        if the feature is not found
#   """
#   def feature_key_num(%__MODULE__{keys: keys}, feature) do
#     Enum.find_index(keys, &(&1 == feature))
#   end

#   defp get_digits_list(list) do
#     _get_digits_list([], list)
#   end

#   defp _get_digits_list(result, []), do: result
#   defp _get_digits_list(result, [key_num, len | digits]) do
#     exten = Enum.take digits, len
#     more = Enum.drop digits, len
#     new_result = result ++ [{key_num, exten}]
#     _get_digits_list(new_result, more)
#   end

#   # From Mscs.Helpers
#   def list_fill!(_list, _fill, len) when len == 0, do: []
#   def list_fill!(list, fill, len) when is_list(list) and len > 0 do
#     _list_fill!([], list, fill, len)
#   end
#   def list_fill!(list, fill, len) when is_binary(list) and len > 0 do
#     _list_fill!([], String.to_char_list(list), fill, len)
#   end

#   defp _list_fill!(result, [], fill, len) do
#     new_len = len - 1
#     if new_len == 0 do
#       result ++ [fill]
#     else
#       _list_fill!(result ++ [fill], [], fill, new_len)
#     end
#   end
#   defp _list_fill!(result, [head|tail], fill, len) do
#     new_len = len - 1
#     cond do
#       new_len == 0 ->
#         result ++ [head]
#       new_len > 0 ->
#         _list_fill!(result ++ [head], tail, fill, new_len)
#     end
#   end

#   def short_to_list(num) do
#     Mscs.Helpers.integer_to_list num, 2
#   end

#   def integer_to_list(num, byte_size) do
#     (byte_size - 1)..0 |> Enum.map(&((num >>> (&1 * 8)) &&& 0xff))
#   end

# end


