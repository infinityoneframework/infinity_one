defmodule OnePages.Github do
  use HTTPoison.Base

  @endpoint "https://api.github.com"
  @project "/repos/infinityoneframework/infinityone-electron"

  @reject_fields ~w(git_id id version_id inserted_at updated_at)a
  @expected_fields :fields |>
    OnePages.Schema.Version.__schema__() |>
    Enum.reject(& &1 in @reject_fields) |>
    Enum.map(&to_string/1)

  @expected_asset_fields :fields |>
    OnePages.Schema.Asset.__schema__() |>
    Enum.reject(& &1 in [:version_id | @reject_fields]) |>
    Enum.map(&to_string/1)

  def process_url(url) do
    @endpoint <> @project <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Map.take(["id", "assets" | @expected_fields])
    |> Enum.map(fn
      {"id", v} -> {:git_id, v}
      {k, v} -> {String.to_atom(k), v}
    end)
    |> Enum.into(%{})
  end

  def latest do
    "/releases/latest"
    |> get!()
    |> cast_assets()
  end

  def cast_assets(%{body: body}) do
    # IO.inspect(@expected_asset_fields, label: "expected_asset_fields")
    body
    |> update_in([:assets], fn assets ->
      Enum.map(assets, fn asset ->
        asset
        # |> IO.inspect(label: "asset")
        |> Enum.filter(& elem(&1, 0) in ["id" | @expected_asset_fields])
        |> Enum.map(fn
          {"id", v} -> {:git_id, v}
          {k, v} -> {String.to_atom(k), v}
        end)
        |> Enum.into(%{})
      end)
    end)
  end

end
