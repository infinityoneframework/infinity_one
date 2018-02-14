defmodule UccChatWeb.AvatarController do
  @moduledoc """
  Handles Avatar related web requests.

  """
  use UccChatWeb, :controller

  import UccChat.AvatarService

  alias UcxUcc.Accounts

  require Logger

  @doc """
  Gets the users default initials based svg avatar.
  """
  def show(conn, %{"username" => username}) do
    conn
    |> put_layout(:none)
    |> put_resp_content_type("image/svg+xml")
    |> render("show.xml", color: get_color(username),
      initials: get_initials(username))
  end

  @doc """
  Create a newly uploaded Avatar and save if on the Users schema.

  Requested through Ajax only. Creates the uploaded file and assigns it
  to the user. Returns the avatar URL to the client for display in the
  users profile page.

  Note that the avatar is uploaded immediately, without any conformation
  from the user. If the user is not happy with the avatar, they can
  upload a new image, or select their default initials based one.

  If the user chooses the initials based avatar on the profile, the one
  created here will be deleted when the user saves the profile page.
  """
  def create(conn, params) do
    user = Accounts.get_user(params["user_id"])

    case Accounts.update_user(user, params) do
      {:ok, user} ->
        render conn, "success.json", url: UccChatWeb.SharedView.avatar_url(user)
      {:error, _} ->
        render conn, "error.json", %{}
    end
  end
end
