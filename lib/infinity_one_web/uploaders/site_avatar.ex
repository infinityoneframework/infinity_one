defmodule InfinityOne.SiteAvatar do
  @moduledoc """
  Arc File Upload descriptor module for SiteAvatar uploads.
  """
  use Arc.Definition
  use Arc.Ecto.Definition
  require Logger

  def __storage, do: Arc.Storage.Local

  @versions [:default]

  @acl :public_read

  @doc """
  White list Avatar file types

  Avatars must be image files, so only image files are supported.
  """
  def validate({file, _}) do
    extname = file.file_name |> Path.extname |> String.downcase
    ~w(.jpg .jpeg .gif .png .ico) |> Enum.member?(extname)
  end


  def transform(:default, {_, %{type: "image" <> _}} = _params) do
    {:convert, "-strip -resize @1600 -format png", :png}
  end

  def filename(:default, {%{file_name: name}, _}) do
    name
  end

  def storage_dir(_version, _) do
    storage_dir()
  end

  def storage_dir() do
    path = "priv/static/uploads/site_avatar"
    if InfinityOne.env == :prod do
      Path.join(Application.app_dir(:infinity_one), path)
    else
      path
    end
  end

end
