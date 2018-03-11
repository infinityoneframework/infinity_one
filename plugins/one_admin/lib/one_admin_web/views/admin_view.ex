defmodule OneAdminWeb.AdminView do
  use OneAdminWeb, :view
  import OneAdminWeb.View.Utils

  def admin_pages do
    OneAdmin.get_pages
  end

  def render_flex_item(page, user \\ nil) do
    cond do
      permission = page.opts[:permission] ->
        InfinityOne.Permissions.has_permission?(user, permission)

      fun = page.opts[:pre_render_check] ->
        fun.(page, user)

      true ->
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
