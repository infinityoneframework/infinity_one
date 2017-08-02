defmodule UccAdminWeb.AdminController do
  use UccAdminWeb, :controller

  alias UccChat.{ChatDat}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUccWeb.LayoutView

  plug :do_layout

  def do_layout(conn, _) do
    put_layout conn, {LayoutView, "app.html"}
  end

  alias UccAdmin.AdminService

  def info(conn, _params) do
    user = Helpers.get_user!(Coherence.current_user(conn) |> Map.get(:id))

    chatd = ChatDat.new(user)
    assigns = [chatd: chatd, user: user, template: "info.html",
      assigns: AdminService.get_args("info", user)]
    render conn, "index.html", assigns
  end

  def index(conn, params) do
    page = params["page"]
    user = Helpers.get_user!(Coherence.current_user(conn) |> Map.get(:id))

    chatd = ChatDat.new(user)
    assigns = [chatd: chatd, user: user, template: page <>".html",
      assigns: AdminService.get_args(page, user)]
    render conn, "index.html", assigns

  end

end
