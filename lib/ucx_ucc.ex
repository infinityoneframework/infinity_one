defmodule UcxUcc do

  @env Mix.env()
  @version UcxUcc.Mixfile.project[:version]

  def env, do: @env
  def version, do: @version

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [deprecated: 1, deprecated: 0]
      require Logger
    end
  end

  defmacro deprecated(message \\ "") do
    function = __CALLER__.function
    quote do
      {name, arity} = unquote(function)
      Logger.error "!!! #{__MODULE__}.#{name}/#{arity} #{unquote(message)} is deprecated!"
    end
  end
end
