defmodule OnePages.Version do
  use OneModel, schema: OnePages.Schema.Version

  def insert_or_update(%{name: name} = params) do
    case get_by(name: name, preload: [:assets]) do
      nil -> change(params)
      version -> change(version, params)
    end
    |> @repo.insert_or_update
  end

  def get_mac_download_link(version) do
    get_asset_field(version, :browser_download_url, fn assets ->
      Enum.find(assets, & &1.name =~ ~r/\.dmg$/)
    end)
  end

  def get_linux_download_link(version) do
    get_asset_field(version, :browser_download_url, fn assets ->
      Enum.find(assets, & &1.name =~ ~r/\.AppImage$/)
    end)
  end

  def get_win_download_link(version) do
    get_asset_field(version, :browser_download_url, fn assets ->
      Enum.find(assets, & &1.name =~ ~r/\.exe$/)
    end)
  end

  def get_asset_field(%{assets: assets}, field, match) when is_list(assets) do
    case match.(assets) do
      nil -> nil
      %{} = item -> Map.get(item, field)
    end
  end

  def get_asset_field(version, field, match) do
    version
    |> preload_schema([:assets])
    |> get_asset_field(field, match)
  end
end
