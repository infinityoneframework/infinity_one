defmodule OneAdminWeb.AdminController do
  use OneAdminWeb, :controller

  alias OneChat.{ChatDat}
  alias OneChat.ServiceHelpers, as: Helpers
  alias InfinityOneWeb.LayoutView

  plug :do_layout

  def do_layout(conn, _) do
    put_layout conn, {LayoutView, "app.html"}
  end

  alias OneAdmin.AdminService

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
