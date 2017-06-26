defmodule UccAdmin.Web.TalonPageController do
  use UccAdmin.Web, :controller
  use Talon.PageController, concern: UccAdmin.Admin

  plug Talon.Plug.LoadConcern, concern: UccAdmin.Admin, web_namespace: Web
  plug Talon.Plug.Theme
  plug Talon.Plug.Layout, layout: {Elixir.UccAdmin.Admin.AdminLte.Web.LayoutView, "app.html"}
  plug Talon.Plug.View

  # TODO

end
