defmodule OneChat.MessageReplacementPatterns do
  require Logger

  def compile do
    compile_patterns()
    |> compile_regex()
    |> create_module()
    |> compile_module()
  end

  defp compile_patterns do
    try do
      case Code.eval_string OneSettings.message_replacement_patterns() do
        {nil, _} -> []
        {res, _} -> res
      end
    rescue
      _ -> []
    end
  end

  defp compile_regex(patterns) do
    Enum.reduce(patterns, [], fn tuple, acc ->
      command = elem(tuple, 3)
      command =
        cond do
          is_tuple(command) -> command
          is_binary(command) && command =~ "." ->
            case String.split(command, ".", trim: true) do
              [_] -> ""
              list when is_list(list) ->
                [fun | modules] = Enum.reverse list
                mod = modules |> Enum.reverse() |> Module.concat()
                {mod, String.to_existing_atom(fun)}
              _ -> ""
            end
          true -> ""
        end
      case Regex.compile(elem(tuple, 1)) do
        {:ok, re} ->
          [{re, elem(tuple, 2), command} | acc]
        _ ->
          Logger.warn "Failed to compile #{elem(tuple, 1)} for name: #{elem(tuple, 0)}"
          acc
      end
    end)
  end

  def create_module(patterns) do
    """
    defmodule OneChat.RunPatterns  do
      require Logger
      @patterns #{inspect patterns}
      def get do
        @patterns
      end
      def run(body) do
        Enum.reduce(@patterns, body, fn {re, sub, command}, body ->
          case command do
            {mod, fun} ->
              apply(mod, fun, [Regex.scan(re, body)])
            _ -> :ok
          end
          Regex.replace(re, body, sub)
        end)
      end
    end
    """
  end

  defp compile_module(module) do
    try do
      Code.eval_string(module)
    rescue
      e ->
        Logger.warn "error: " <> inspect(e)
        Logger.warn "Could not compile module: #{inspect module}"
    end
  end
end
