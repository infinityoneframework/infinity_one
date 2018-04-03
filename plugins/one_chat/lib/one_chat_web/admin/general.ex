defmodule OneChatWeb.Admin.Page.General do
  use OneAdmin.Page

  alias InfinityOne.{Repo, Hooks, Settings.General}
  alias OneAdminWeb.View.Utils

  def add_page do
    new(
      "admin_general",
      __MODULE__,
      ~g(General),
      OneChatWeb.AdminView,
      "general.html",
      60,
      pre_render_check: &check_perissions/2,
      permission: "view-general-administration"
    )
  end

  def args(page, user, _sender, socket) do
    general = General.get()
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: general |> General.changeset()
        |> Hooks.all_users_post_filter,
    ] ++ Utils.changed_bindings(General, general), user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-general-administration"
  end
end
