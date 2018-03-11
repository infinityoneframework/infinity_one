defmodule OneChatWeb.API.MessageView do
  use OneChatWeb, :view

  require Logger

  def render("show.json", %{success: data}) do
    # Logger.warn "data: " <> inspect(data)
    Enum.into(data, %{success: true})
  end

  def render("show.json", %{error: data}) do
    # Logger.warn "data: " <> inspect(data)
    Enum.into(data, %{success: false})
  end

  def render("create.json", %{success: data}) do
    Enum.into(data, %{success: true})
  end

  def render("create.json", %{error: data}) do
    Enum.into(data, %{success: false})
  end
end
