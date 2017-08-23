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
      [pre_render_check: &UccChatWeb.Admin.view_message_admin_permission?/2]
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Layout.get |> Layout.changeset,
    ], user, page, socket}
  end

end
