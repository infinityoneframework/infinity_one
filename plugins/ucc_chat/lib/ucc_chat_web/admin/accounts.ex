defmodule UccChatWeb.Admin.Page.Accounts do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks, Settings.Accounts}

  def add_page do
    new("admin_accounts", __MODULE__, ~g(Accounts), UccChatWeb.AdminView, "accounts.html", 55)
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Accounts.get() |> Accounts.changeset()
        |> Hooks.all_users_post_filter,
    ], user, page, socket}
  end

end
