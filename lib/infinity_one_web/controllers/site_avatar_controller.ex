defmodule InfinityOneWeb.SiteAvatarController do
  @moduledoc """
  Handles SiteAvatar Uploads

  """
  use InfinityOneWeb, :controller

  alias InfinityOne.Accounts
  alias InfinityOne.Settings.General
  alias InfinityOne.SiteAvatar

  require Logger

  @doc """
  Create a newly uploaded SiteAvatar and saves if on the General settings schema

  Requested through Ajax only. Creates the uploaded file and assigns it
  to the schema. Returns the file URL to the client for display in the
  admin page.
  """
  def create(conn, params) do

    general = General.get()
    old_site_avatar = general.site_avatar

    case General.update(general, params) do
      {:ok, general} ->
        SiteAvatar.delete({old_site_avatar, nil})
        render conn, "success.json", url: SiteAvatar.url(general.site_avatar)
          |> OneChatWeb.SharedView.view_url()
      {:error, _} ->
        render conn, "error.json", %{}
    end
  end
end
