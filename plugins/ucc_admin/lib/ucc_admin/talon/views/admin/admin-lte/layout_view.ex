defmodule UccAdmin.Admin.AdminLte.Web.LayoutView do
  use UccAdmin.Talon.Web, which: :view, theme: "admin/admin-lte", module: UccAdmin.Admin.AdminLte.Web

  alias __MODULE__

  def nav_resource_link_decorator(conn, name, path) do
    path_name = path |> String.split("/") |> List.last()

    cond do
      path_name == "dashboard" ->
        {"fa fa-dashboard", ""}
      is_nil concern(conn).talon_page(path_name) ->
        {"nav-label label label-info", String.first(name)}
      true ->
        {"nav-label label bg-green", String.first(name)}
    end
  end
end
