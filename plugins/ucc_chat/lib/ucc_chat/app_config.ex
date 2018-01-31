defmodule UccChat.AppConfig do
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
      def unquote(key)(opts \\ unquote(default)) do
        Application.get_env(:ucx_ucc, :ucc_chat, [])
        |> Keyword.get(unquote(key), opts)
      end
    key ->
      def unquote(key)(opts \\ nil) do
        Application.get_env(:ucx_ucc, :ucc_chat, [])
        |> Keyword.get(unquote(key), opts)
      end
  end)
end
