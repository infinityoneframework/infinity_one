defmodule UccSettings do
  @moduledoc """
  UcxUcc Pluging for managing settings for the main app and all the
  plugins
  """

  :ucx_ucc
  |> Application.get_env(:settings_modules, [])
  |> Enum.map(fn module ->
    if not Code.ensure_compiled?(module), do: raise("module #{module} not compiled")
    Enum.map module.fields(), fn field ->
      @field field
      @mod module
      def unquote(field)() do
        apply(@mod, @field, [])
      end
      def unquote(field)(config) do
        apply(@mod, @field, [config])
      end
    end
  end)

  def load_all do
    for config <- UccSettings.Settings.list_configs(), into: %{} do
      {String.to_atom(config.name), config.value}
    end
  end

  def init_all do
    :ucx_ucc
    |> Application.get_env(:settings_modules, [])
    |> Enum.map(fn module ->
      apply module, :init, []
    end)
  end
end
