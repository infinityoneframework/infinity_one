defmodule UccSettings.Utils do

  def module_key(module) do
    module
    |> Module.split
    |> List.last
    |> Inflex.underscore
    |> String.to_atom
  end

end
