defmodule OneSettings do
  @moduledoc """
  InfinityOne Pluging for managing settings for the main app and all the
  plugins
  """

  alias OneSettings.Utils

  defmacro __using__(_) do
    quote bind_quoted: [] do
      :infinity_one
      |> Application.get_env(:settings_modules, [])
      |> Enum.map(fn module ->
        if not Code.ensure_compiled?(module), do: raise("module #{module} not compiled")

        module.schema().__schema__(:fields)
        |> Enum.reject(& &1 == :id)
        |> Enum.map(fn field ->
          @field field
          @mod module
          def unquote(field)() do
            apply(@mod, @field, [])
          end
          def unquote(field)(config) do
            apply(@mod, @field, [config])
          end
        end)
      end)
    end
  end

  :infinity_one
  |> Application.get_env(:settings_modules, [])
  |> Enum.map(fn module ->
    if not Code.ensure_compiled?(module), do: raise("module #{module} not compiled")

    module.schema().__schema__(:fields)
    |> Enum.reject(& &1 == :id)
    |> Enum.map(fn field ->
      # IO.inspect {module, field}, label: "{module, field}"
      @field field
      @mod module
      def unquote(field)() do
        apply(@mod, @field, [])
      end
      def unquote(field)(config) do
        apply(@mod, @field, [config])
      end
    end)
  end)

  @module_map :infinity_one |>
    Application.get_env(:settings_modules, []) |>
    Enum.map(fn m -> {m |> Module.split() |> List.last() |> Module.concat(nil), m} end) |>
    Enum.into(%{})

  @doc """
  Return a map of the module.

  Returns a map of the full module indexed by the last segment of the module.
  """
  def module_map, do: @module_map

  @doc """
  Get the fill module give either an Atom or a binary.
  """
  def module_map(module) when is_atom(module) do
    Map.get(@module_map, module)
  end

  def module_map(module) when is_binary(module) do
    Map.get(@module_map, module |> Inflex.camelize() |> Module.concat(nil))
  end

  fields =
    :infinity_one
    |> Application.get_env(:settings_modules, [])
    |> Enum.map(fn module ->
      {Utils.module_key(module), module.schema().__struct__}
    end)

  defstruct fields

  @doc """
  Load all configuration from the database.
  """
  @spec get_all() :: Keyword.t
  def get_all do
    opts =
      :infinity_one
      |> Application.get_env(:settings_modules, [])
      |> Enum.map(fn module ->
        {Utils.module_key(module), module.get()}
      end)
    struct %__MODULE__{}, opts
  end

  @doc """
  Initialize the settings database to its defaults.
  """
  @spec init_all() :: term
  def init_all do
    :infinity_one
    |> Application.get_env(:settings_modules, [])
    |> Enum.map(fn module ->
      module.init
      # apply module, :init, []
    end)
  end

  # defp fields do
  #   __MODULE__.__struct__
  #   |> Enum.map(fn {name, value} ->
  #     {name, value.__stuct__}
  #   end)
  # end
end
