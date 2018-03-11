defmodule OneChatWeb.Admin.Page.Accounts do
  use OneAdmin.Page

  alias InfinityOne.{Repo, Hooks, Settings.Accounts}

  def add_page do
    new(
      "admin_accounts",
      __MODULE__,
      ~g(Accounts),
      OneChatWeb.AdminView,
      "accounts.html",
      55,
      pre_render_check: &check_perissions/2,
      permission: "view-accounts-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Accounts.get() |> Accounts.changeset()
        |> Hooks.all_users_post_filter,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-accounts-administration"
  end
end
