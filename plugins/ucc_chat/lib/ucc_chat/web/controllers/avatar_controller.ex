defmodule UccChat.Web.AvatarController do
  use UccChat.Web, :controller
  import UccChat.AvatarService

  def show(conn, %{"username" => username}) do
    # xml = UccChat.AvatarService.avatar_initials(username)
    conn
    |> put_layout(:none)
    |> put_resp_content_type("image/svg+xml")
    |> render("show.xml", color: get_color(username), initials: get_initials(username))
  end

end
