defmodule InfinityOne do

  @env Mix.env()
  @version InfinityOne.Mixfile.project[:version]
  @brandname Application.get_env :infinity_one, :brand_name, "InfinityOne"
  @name InfinityOne.Mixfile.project[:app]

  def env, do: @env
  def version, do: @version
  def name, do: @name

  def brandname, do: @brandname

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
