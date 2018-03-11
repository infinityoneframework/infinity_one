defmodule OneChat.AppConfig do
  @moduledoc """
  Simple wrapper around select config items.

  Provides a functions that wrap `Application.get_env` for some of the
  popular configuration items.
  """
  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
    end
  end


  [
    {:page_size, 76}
    # :page_size,
    # {:token_assigns_key, :user_token},
  ]
  |> Enum.each(fn
    {key, default} ->
      @doc """
      Get the #{key} configuration item.

      Returns the default `#{default}` if a default is not provided.
      """
      def unquote(key)(opts \\ unquote(default)) do
        Application.get_env(:infinity_one, :one_chat, [])
        |> Keyword.get(unquote(key), opts)
      end
    key ->
      @doc """
      Get the #{key} configuration item.

      Returns `nil` if a default is not provided.
      """
      def unquote(key)(opts \\ nil) do
        Application.get_env(:infinity_one, :one_chat, [])
        |> Keyword.get(unquote(key), opts)
      end
  end)
end
