defmodule OnePages.VersionTest do
  use OnePages.DataCase

  alias OnePages.Version
  alias OnePages.Schema.Version, as: VersionSchema


  @valid_attrs %{assets_url: "some assets_url", body: "some body", draft: true, git_id: 42, html_url: "some html_url", name: "some name", prerelease: true, tag_name: "some tag_name", url: "some url"}
  @update_attrs %{assets_url: "some updated assets_url", body: "some updated body", draft: false, git_id: 43, html_url: "some updated html_url", name: "some updated name", prerelease: false, tag_name: "some updated tag_name", url: "some updated url"}
  @invalid_attrs %{assets_url: nil, body: nil, draft: nil, git_id: nil, html_url: nil, name: nil, prerelease: nil, tag_name: nil, url: nil}

  def version_fixture(attrs \\ %{}) do
    {:ok, version} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Version.create()

    version
  end

  test "list/0 returns all app_versions" do
    version = version_fixture()
    [version1] = Version.list()
    assert schema_eq(version, version1)
  end

  test "get!/1 returns the version with given id" do
    version = version_fixture()
    assert schema_eq(Version.get!(version.id), version)
  end

  test "create/1 with valid data creates a version" do
    assert {:ok, %VersionSchema{} = version} = Version.create(@valid_attrs)
    assert version.assets_url == "some assets_url"
    assert version.body == "some body"
    assert version.draft == true
    assert version.git_id == 42
    assert version.html_url == "some html_url"
    assert version.name == "some name"
    assert version.prerelease == true
    assert version.tag_name == "some tag_name"
    assert version.url == "some url"
  end

  test "create/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Version.create(@invalid_attrs)
  end

  test "update/2 with valid data updates the version" do
    version = version_fixture()
    assert {:ok, version} = Version.update(version, @update_attrs)
    assert %VersionSchema{} = version
    assert version.assets_url == "some updated assets_url"
    assert version.body == "some updated body"
    assert version.draft == false
    assert version.git_id == 43
    assert version.html_url == "some updated html_url"
    assert version.name == "some updated name"
    assert version.prerelease == false
    assert version.tag_name == "some updated tag_name"
    assert version.url == "some updated url"
  end

  test "update/2 with invalid data returns error changeset" do
    version = version_fixture()
    assert {:error, %Ecto.Changeset{}} = Version.update(version, @invalid_attrs)
    assert schema_eq(version, Version.get!(version.id))
  end

  test "delete/1 deletes the version" do
    version = version_fixture()
    assert {:ok, %VersionSchema{}} = Version.delete(version)
    assert_raise Ecto.NoResultsError, fn -> Version.get!(version.id) end
  end

  test "change/1 returns a version changeset" do
    version = version_fixture()
    assert %Ecto.Changeset{} = Version.change(version)
  end

end
