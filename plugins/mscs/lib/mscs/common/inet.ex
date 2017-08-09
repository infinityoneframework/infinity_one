# Copyright (C) E-MetroTel, 2015 - All Rights Reserved 
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of 
# a written license agreement with E-MetroTel.

defmodule Inet do
  @moduledoc """
  Module to work with Inet data
  """

  defmodule Parse do
    @moduledoc """
    Parses Inet addresses
    """

    alias Mscs.Helpers
    use Bitwise

    @doc """
    Returns the integer representation of an ip address tuple 
    """
    def address(ip) when is_tuple(ip) do
      address Tuple.to_list(ip)
    end 

    @doc """
    Returns the integer representation of an ip address binary (string)
    """
    def address(ip) when is_binary(ip) do
      address String.to_char_list(ip)
    end 

    @doc """
    Returns the integer representation of an ip address list

    Accepts the following list formats:
    * [10, 30, 15, 130]
    * '10.30.15.130'

    """
    def address(ip) when is_list(ip) do
      sz = length(ip)
      cond do
        sz < 4 -> 
          throw {:error, :badarg}
        sz == 4 -> 
          Helpers.list_to_integer ip
        sz > 7 and sz < 15 -> 
          # a char list
          {:ok, tuple} = :inet_parse.address ip
          Tuple.to_list(tuple) |> Helpers.list_to_integer
      end
    end
    @doc """
    Returns the integer representation of an ip address integer

    Does nothing but return the input. 
    """
    def address(ip) when is_integer(ip), do: ip
    
    @doc """
    Returns the binary (string) representation of an ip
    """
    def address_to_s(ip) when is_tuple(ip) do
      :inet_parse.ntoa(ip) |> IO.chardata_to_string
    end
    def address_to_s(ip) when is_number(ip) do
      Enum.reduce(0..3, "", fn(x, acc) ->
        dot = if x == 0, do: "", else: "."
        "#{(ip >>> ( 8 * x )) &&& 0xff}" <> dot <> acc
      end)
    end

    def address_to_s(ip) when is_list(ip) do
      address_to_tuple(ip) |> address_to_s
    end

    @doc """
    Returns the list representation of an ip address
    """
    def address_to_list(ip) when is_binary(ip) do
      {:ok, tuple} = :inet.parse_address(String.to_char_list ip)
      Tuple.to_list tuple
    end
    def address_to_list(ip) when is_integer(ip) do
      address_to_s(ip) |> address_to_list
    end 

    @doc """
    Returns the tuple representation of an ip address
    """
    def address_to_tuple(ip) when is_binary(ip) do
      String.to_char_list(ip) |> address_to_tuple
    end
    def address_to_tuple(ip) when is_number(ip) do
      address_to_s(ip) |> address_to_tuple
    end
    def address_to_tuple(ip) when is_list(ip) and length(ip) == 4 do
      List.to_tuple ip
    end
    def address_to_tuple(ip) when is_list(ip) do
      {:ok, tuple} = :inet.parse_address(ip)
      tuple
    end
    def address_to_tuple(ip) when is_tuple(ip), do: ip
  end
  
end
