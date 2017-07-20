defmodule UcxUcc.Web.SidebarView do
  use UcxUcc.Web, :view

  def username(conn) do
    Coherence.current_user(conn) |> Map.get(:username)
  end

  # def avatar_url(username) when is_binary(username) do
  #   "/avatar/" <> username
  # end

  def current_user_avatar_url(conn) do
    conn |> username |> avatar_url
  end
end
