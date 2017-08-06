defmodule UccWebrtc.ClientDevice do
  use UccModel, schema: UccWebrtc.Schema.ClientDevice

  # @spec build_client_devices(installed_devices : nil | List.t) :: Map.t
  def build_client_devices(nil), do: initial_state()
  def build_client_devices(installed_devices) do
    installed_devices
    # |> IO.inspect(label: "installed_devices")
    |> Enum.reduce(initial_state(), fn
      %{"kind" => "audioinput", "id" => id, "label" => label}, acc ->
        update_in acc, [:input], &([{label, id} | &1])
      %{"kind" => "audiooutput", "id" => id, "label" => label}, acc ->
        update_in acc, [:output], &([{label, id} | &1])
      %{"kind" => "videoinput", "id" => id, "label" => label}, acc ->
        update_in acc, [:video], &([{label, id} | &1])
    end)
    |> update_in([:input], &Enum.reverse/1)
    |> update_in([:output], &Enum.reverse/1)
    |> update_in([:video], &Enum.reverse/1)
  end

  defp initial_state do
    %{input: [], output: [], video: []}
  end

end
