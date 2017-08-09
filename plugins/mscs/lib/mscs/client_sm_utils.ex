defmodule Mscs.ClientSm.Utils do
  @moduledoc """
  Various helpers for ClientSm
  """

  @doc """
  Create an initial list of keys

  Used to create the `ClientProxy` data structure. Moved into a
  separate module since this is used in a `defstruct` and cannot
  be in the same module.
  """
  def init_keys(count, fun), do: init_keys(count, 0, "&nbsp;", fun)
  def init_keys(count, start, fun) when is_integer(start),
    do: init_keys(count, start, "&nbsp;", fun)
  def init_keys(count, default, fun) when is_binary(default),
    do: init_keys(count, 0, default, fun)
  def init_keys(count, start, default, fun) do
    for i <- 0..count do
      val = i + start
      {val, fun.(val, default)}
    end
    |> Enum.into(%{})
  end

  @doc """
  Replaces an empty string with a `&nbsp;`.

  Takes a char_list or a binary an input and returns:

  * a `&nbsp;` if the string is empty
  * the original string otherwise
  """
  def encoded_empty_string(text) when is_list(text) do
    if Enum.all?(text, &(&1 == 0x20)), do: '&nbsp;', else: text
  end
  def encoded_empty_string(text) when is_binary(text) do
    if String.match?(text, ~r/(^ +$)|(^$)/), do: "&nbsp;", else: text
  end

  @doc """
  Functions to handle dsiplay of messages
  """
  def ignore_message?(list, message) when is_tuple(message) do
    Enum.any?(list, &(ignore_tuple?(&1, message)))
  end
  def ignore_message?(list, message) when is_atom(message) do
    Enum.any?(list, &(message == &1))
  end
  def ignore_tuple?(item, message) when is_tuple(item) do
    _ignore_tuple?(true, Tuple.to_list(item), Tuple.to_list(message))
  end
  def ignore_tuple?(_item, _), do: false
  defp _ignore_tuple?(false, _, _), do: false     # return on any false
  defp _ignore_tuple?(true, [], _), do: true      # done the normal true case
  defp _ignore_tuple?(true, _, []), do: false     # item is large then the message
  defp _ignore_tuple?(true, [h|t], [msg_h|msg_t]) do
    _ignore_tuple?(h == msg_h, t, msg_t)
  end

  defmacro idle_icon_state?(st, cad) do
    quote(do: unquote(st) == 0 and unquote(cad) == 1)
  end
  defmacro active_icon_state?(st, cad) do
    quote(do: unquote(st) == 4 and unquote(cad) == 1)
  end
  defmacro hold_icon_state?(st, cad) do
    quote(do: unquote(st) == 6 and unquote(cad) == 1)
  end
  defmacro dialtone_icon_state?(st, cad) do
    quote(do: unquote(st) == 10 and unquote(cad) == 1)
  end
end
