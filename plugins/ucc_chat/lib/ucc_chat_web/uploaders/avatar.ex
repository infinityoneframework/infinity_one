defmodule UccChat.Avatar do
  @moduledoc """
  Arc File Upload descriptor module for Avatar uploads.
  """
  use Arc.Definition

  # Include ecto support (requires package arc_ecto installed):
  use Arc.Ecto.Definition
  require Logger

  def __storage, do: Arc.Storage.Local

  @versions [:avatar, :thumb]

  @acl :public_read

  @doc """
  White list Avatar file types

  Avatars must be image files, so only image files are supported.
  """
  def validate({file, _}) do
    extname = file.file_name |> Path.extname |> String.downcase
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(extname)
  end


  def transform(:avatar, {_, %{type: "image" <> _}} = _params) do
    {:convert, "-strip -resize @109120 -format png", :png}
  end
  def transform(:thumb, {_, %{type: "image" <> _}} = _params) do
    {:convert, "-strip -resize @1600 -format png", :png}
  end

  def filename(:thumb, _params), do: :thumb
  def filename(:avatar, _params), do: :avatar

  # Override the persisted filenames:
  # def filename(version, params) do
  #   Logger.warn "filename version: #{inspect version}, params: #{inspect params}"
  #   version
  # end

  def storage_dir(_version, {_file, scope}) do
    storage_dir(scope)
  end

  def storage_dir(scope) do
    path = "priv/static/uploads/avatars/#{scope.id}"
    if UcxUcc.env == :prod do
      Path.join(Application.app_dir(:ucx_ucc), path)
    else
      path
    end
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end
