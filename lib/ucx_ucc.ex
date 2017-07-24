defmodule UcxUcc do

  @env Mix.env()
  def env, do: @env

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [deprecated: 1, deprecated: 0]
      require Logger
    end
  end

  defmacro deprecated(message \\ "") do
    name = __CALLER__.function
    quote do
      Logger.error "!!! #{__MODULE__}.#{unquote(name)} #{unquote(message)} is deprecated!"
    end
  end
end
