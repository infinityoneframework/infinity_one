defmodule InfinityOneWeb.API.PublicView do
  @moduledoc """
  View for handling API requests not requiring authentication.

  Main purpose of this module is to support the desktop clients.
  """
  use InfinityOneWeb, :view

  @doc """
  Fetches the server settings.
  """
  def render("server_settings.json", %{data: data}) do
    Enum.into(data, %{result: :success})
  end
end
