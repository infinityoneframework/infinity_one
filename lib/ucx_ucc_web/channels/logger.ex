defmodule UccLogger do

  require Logger

  defmacro __using__(opts \\ []) do
    quote do
      require Logger
      import unquote(__MODULE__)
      if Keyword.get(unquote(opts), :debug, :true) do
        def debug, do: true
      else
        def debug, do: false
      end
    end
  end

  defmacro trace(event, params, msg \\ "") do
    modules =
      case Application.get_env :ucx_ucc, :ucc_tracer_modules, [] do
        :all -> [:all]
        other -> other
      end

    level = Application.get_env :ucx_ucc, :ucc_tracer_level, :debug

    match =
      Enum.find(modules, fn
        {__MODULE__, _} -> true
        __MODULE__      -> true
        :all            -> true
        _               -> false
      end)
      |> case do
        {_, mod_level} -> mod_level
        __MODULE__     -> level
        :all           -> level
        _              -> false
      end
    if match do
      quote location: :keep do
        the_level = unquote(match)
        msg1 =
          case unquote(msg) do
            "" -> ""
            mg -> mg <> ", "
          end

        Logger.log the_level, fn -> "TRACE: #{unquote(event)}: #{msg1}params: " <>
          inspect(unquote(params)) end
      else
        quote do
          _ = fn -> {unquote(event), unquote(params), unquote(msg)} end
        end
      end
    end
  end

  defmacro debug(event, params, msg \\ "") do
    name = __CALLER__.function |> elem(0) |> to_string
    quote location: :keep do
      msg1 = case unquote(msg) do
        "" -> ""
        mg -> mg <> ", "
      end

      if debug() do
        if UcxUcc.env() == :prod do
          Logger.debug "%% " <> inspect(__MODULE__) <>
            ".#{unquote(name)} #{unquote(event)}: #{msg1}params: " <>
            "#{inspect unquote(params)}"
        else
          Logger.info "%% " <> inspect(__MODULE__) <>
            ".#{unquote(name)} #{unquote(event)}: #{msg1}params: " <>
            "#{inspect unquote(params)}"
        end
      end
    end
  end

  defmacro warn(event, params, msg \\ "") do
    name = __CALLER__.function |> elem(0) |> to_string
    quote location: :keep do
      msg1 = case unquote(msg) do
        "" -> ""
        mg -> mg <> ", "
      end

      if debug() do
        Logger.warn "%% " <> inspect(__MODULE__) <> ".#{unquote(name)} " <>
          "#{unquote(event)}: #{msg1}params: #{inspect unquote(params)}"
      end
    end
  end
  def log_inspect(term, level, opts) do
    {label, opts} = Keyword.pop(opts, :label)
    label =
      if label do
        label <> ": "
      else
        ""
      end
    Logger.log level, label <> inspect(term, opts)
    term
  end
end
