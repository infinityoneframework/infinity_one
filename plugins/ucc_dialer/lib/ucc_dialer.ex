defmodule UccDialer do
  @moduledoc """
  Click to call implementation for UccChat.

  An interface for external PBX or calling service for handling calling
  phone numbers using a third party phone calling service like a PBX or
  web service.

  This module requires an adapter implementation which is configured with

      config :ucx_ucc, :dialer_adapter, SomeModule

  The adapter must implement the `dial/4` function.

  The interface also supports digit translation, which is gone here, before
  the call to the adapter. The translator uses uses a pattern matching approach
  taken from the asterisk open source PBX, with the following definition.

  `N` - matches digits 2-9
  `Z` - matches digits 1-9
  `X` - matches digits 0-9

  For example, to match a 10 digit number and insert a leading 1, use the
  following `"1, NXXNXXXXXX"`, where the initial `1` is the inserted digit and
  the trailing pattern it the matching specification.

      iex> UccDialer.translate_digits("5555555555", "1, NXXNXXXXXX")
      "15555555555"
      iex> UccDialer.translate_digits("15555555555", "1, NXXNXXXXXX")
      "15555555555"
      iex> UccDialer.translate_digits("1234", "1, NXXNXXXXXX")
      "1234"

  Multiple translations can be defined by using a `,` to separate each. For
  example, to add a second rule to add a 613 prefix to 7 digit numbers, use the
  following `"1, NXXNXXXXXX, 613, NXXXXXX"`

      iex> UccDialer.translate_digits("2234567", "1, NXXNXXXXXX, 613, NXXXXXX")
      "6132234567"
      iex> UccDialer.translate_digits("7322608", "1613, 73XXXXX")
      "16137322608"
  """

  require Logger

  @adapter Application.get_env(:ucx_ucc, :dialer_adapter, nil)

  @doc """
  Call the dial function on the configured adapter.

  Calls a number by running the `dial/4` function on the configured adapter.
  """
  def dial(user, caller, number, opts), do: dial({user, caller}, number, opts)

  def dial({_user, nil}, _number, _opts), do: nil

  def dial({user, caller}, number, opts) do
    # Logger.warn "dial number: #{inspect number}"
    adapter = opts[:adapter] || @adapter
    if adapter do
      adapter.dial(user, caller, translate_digits(number), opts)
    else
      Logger.error """
        UccDialer attempt to dial number #{number} without a configured adapter.
        Please configure and adapter with:
          config :ucc_dialer, :dialer_adapter, DialerModule
        """
    end
  end

  @doc """
  Apply configured digit translation rules to the called number.
  """
  def translate_digits(digits, translation \\ nil) do
    translation = translation || Application.get_env(:ucc_dialer, :dial_translation, "")

    translation
    |> String.replace(" ", "")
    |> String.split(",")
    |> Enum.chunk(2)
    |> process_patterns(digits)
  end

  defp process_patterns(list, digits) do
    Enum.find_value(list, digits, fn([insert_digits, pattern]) ->
      ("^" <> pattern)
      |> String.replace("N", "[2-9]")
      |> String.replace("Z", "[1-9]")
      |> String.replace("X", "[0-9]")
      |> Regex.compile!
      |> find_and_replace(digits, "#{insert_digits}\\0")
    end)
  end

  defp find_and_replace(regex, digits, replace_str) do
    if Regex.run(regex, digits),
      do: Regex.replace(regex, digits, replace_str)
  end
end
