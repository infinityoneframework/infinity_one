defmodule UccChatWeb.Admin.Page.Layout do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks}
  alias UccChat.Settings.Layout

  def add_page do
    new(
      "admin_layout",
      __MODULE__,
      ~g(Layout),
      UccChatWeb.AdminView,
      "layout.html",
      75,
      pre_render_check: &check_perissions/2,
      permission: "view-layout-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Layout.get |> Layout.changeset,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-layout-administration"
  end
end
