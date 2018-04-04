defmodule OnePages.TestAsset do
  use OnePages.DataCase

  alias OnePages.Asset
  alias OnePages.Schema.Asset, as: AssetSchema

  @valid_attrs %{browser_download_url: "some browser_download_url", content_type: "some content_type", download_count: 42, git_id: 42, name: "some name", state: "some state", url: "some url"}
  @update_attrs %{browser_download_url: "some updated browser_download_url", content_type: "some updated content_type", download_count: 43, git_id: 43, name: "some updated name", state: "some updated state", url: "some updated url"}
  @invalid_attrs %{browser_download_url: nil, content_type: nil, download_count: nil, git_id: nil, name: nil, state: nil, url: nil}

  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Asset.create()

    asset
  end

  test "list/0 returns all assets" do
    asset = asset_fixture()
    [asset1] = Asset.list()
    assert schema_eq(asset1, asset)
  end

  test "get!/1 returns the asset with given id" do
    asset = asset_fixture()
    assert schema_eq(Asset.get!(asset.id), asset)
  end

  test "create/1 with valid data creates a asset" do
    assert {:ok, %AssetSchema{} = asset} = Asset.create(@valid_attrs)
    assert asset.browser_download_url == "some browser_download_url"
    assert asset.content_type == "some content_type"
    assert asset.download_count == 42
    assert asset.git_id == 42
    assert asset.name == "some name"
    assert asset.state == "some state"
    assert asset.url == "some url"
  end

  test "create/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Asset.create(@invalid_attrs)
  end

  test "update/2 with valid data updates the asset" do
    asset = asset_fixture()
    assert {:ok, asset} = Asset.update(asset, @update_attrs)
    assert %AssetSchema{} = asset
    assert asset.browser_download_url == "some updated browser_download_url"
    assert asset.content_type == "some updated content_type"
    assert asset.download_count == 43
    assert asset.git_id == 43
    assert asset.name == "some updated name"
    assert asset.state == "some updated state"
    assert asset.url == "some updated url"
  end

  test "update/2 with invalid data returns error changeset" do
    asset = asset_fixture()
    assert {:error, %Ecto.Changeset{}} = Asset.update(asset, @invalid_attrs)
    assert schema_eq(asset, Asset.get!(asset.id))
  end

  test "delete/1 deletes the asset" do
    asset = asset_fixture()
    assert {:ok, %AssetSchema{}} = Asset.delete(asset)
    assert_raise Ecto.NoResultsError, fn -> Asset.get!(asset.id) end
  end

  test "change/1 returns a asset changeset" do
    asset = asset_fixture()
    assert %Ecto.Changeset{} = Asset.change(asset)
  end
end
