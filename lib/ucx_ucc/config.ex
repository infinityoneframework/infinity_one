defmodule UcxUcc.Config do
  @moduledoc """
  Handle general configuration.

  """

  @doc """
  Handle config items that may return :system tuple.

  """
  @spec get_env(atom, atom, any) :: any
  def get_env(app, item, default \\ nil) do
    case Application.get_env app, item, default do
      {:system, env} -> System.get_env(env) || default
      other -> other
    end
  end

  def deep_parse([]), do: []
  def deep_parse([h | t]), do: [deep_parse(h) | deep_parse(t)]
  def deep_parse({item, list}) when is_list(list) or is_tuple(list), do: {deep_parse(item), deep_parse(list)}
  def deep_parse({item, {:system, env}}), do: {item, System.get_env(env)}
  def deep_parse({:system, env}), do: System.get_env(env)
  def deep_parse({item, item2}), do: {item, item2}
  def deep_parse(item), do: item

end
