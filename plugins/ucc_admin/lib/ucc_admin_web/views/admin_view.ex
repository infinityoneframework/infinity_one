defmodule UccAdminWeb.AdminView do
  use UccAdminWeb, :view
  import UccAdminWeb.View.Utils

  def admin_pages do
    UccAdmin.get_pages
  end

  def render_flex_item(page, user \\ nil) do
    if fun = page.opts[:pre_render_check] do
      fun.(page, user)
    else
      true
    end
    |> do_render_flex_item(page, user)
  end

  defp do_render_flex_item(true, page, user) do
    if render_link = page.opts[:render_link] do
      render_link.(page, user)
    else
      render "admin_link.html", page: page
    end
  end

  defp do_render_flex_item(_, _page, _user) do
    ""
  end
end
