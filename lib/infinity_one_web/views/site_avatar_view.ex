defmodule InfinityOneWeb.SiteAvatarView do
  @moduledoc """
  View related concerns for the SiteAvatar Controller.
  """
  use InfinityOneWeb, :view

  @doc """
  Render json responses for the Upload avatar feature.
  """
  def render("success.json", opts) do
    %{success: true, url: opts[:url]}
  end

  def render("error.json", _opts) do
    %{error: true}
  end

end
