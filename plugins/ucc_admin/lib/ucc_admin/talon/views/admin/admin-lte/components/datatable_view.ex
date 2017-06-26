defmodule UccAdmin.Admin.AdminLte.Web.DatatableView do
  use UccAdmin.Talon.Web, which: :component_view, theme: "admin/admin-lte", module: UccAdmin.Admin.AdminLte.Web
  use Talon.Components.Datatable, __MODULE__

end
