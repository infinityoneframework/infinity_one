defmodule UccAdmin.Web.AdminResourceController do
  use UccAdmin.Web, :controller
  use Talon.Controller, repo: UccAdmin.Repo, concern: UccAdmin.Admin

  plug Talon.Plug.LoadConcern, concern: UccAdmin.Admin, web_namespace: Web
  plug Talon.Plug.LoadResource
  plug Talon.Plug.LoadAssociations
  plug Talon.Plug.LoadAssociatedCollections when action in [:new, :edit]
  plug Talon.Plug.Theme
  plug Talon.Plug.Layout, layout: {Elixir.UccAdmin.Admin.AdminLte.Web.LayoutView, "app.html"}
  plug Talon.Plug.View
  
  # Each of the controller actions can be overridden in this module

  # Override the show action
  # def show(conn, params) do
  #   IO.inspect params, label: params
  #   conn
  #   |> assign(:something, "something")
  #   |> super(paams)
  # end
  
end
