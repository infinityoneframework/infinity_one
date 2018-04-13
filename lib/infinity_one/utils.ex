defmodule InfinityOne.Utils do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro is_falsey(value) do
    quote do
      (unquote(value) == nil or unquote(value) == false)
    end
  end
  defmacro is_falsy(value) do
    quote do
      is_falsey(unquote(value))
    end
  end

  defmacro is_truthy(value) do
    quote do
      (not is_falsey(unquote(value)))
    end
  end

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

  def to_camel_case(atom) when is_atom(atom), do: atom |> to_string |> to_camel_case
  def to_camel_case(string) do
    string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  @doc """
  Generate a random string.

  Returns a random string, with the given length.
  """
  @spec random_string(integer) :: binary
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @doc ~S"""
    Truncates a given text after a given :length if text is longer than :length (defaults to 20).
    If :middle option is passed removes the middle of the given text.

    ## Examples:

      iex> truncate("Lorem ipsum dolor sit amet")
      "Lorem ipsum dolor s…"
      iex> truncate("Lorem ipsum dolor sit amet", length: 6)
      "Lorem…"
      iex> truncate("Lorem ipsum dolor sit amet", middle: true)
      "Lorem ipsu… sit amet"
      iex> truncate("Lorem ipsum dolor sit amet", middle: 5, length: 20)
      "Lorem…dolor sit amet"
  """
  def truncate(text, options \\ []) do
    len = options[:length] || 20
    if String.length(text) > len do
      len = len - 1
      if options[:middle] do
        mid =
          if is_number(options[:middle]) do
            options[:middle] - 1
          else
            rem(len, 2) == 0 && div(len-1, 2) || div(len, 2)
          end
        start2 = String.length(text) - len + mid + 1
        "#{String.slice(text, 0..mid)}…#{String.slice(text, start2..-1)}"
      else
        sz = len - 1
        "#{String.slice(text, 0..sz)}…"
      end
    else
      text
    end
  end
end
