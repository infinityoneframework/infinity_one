defmodule OneChatWeb.AvatarView do
  @moduledoc """
  View related concerns for the Avatar Controller.
  """
  use OneChatWeb, :view

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
