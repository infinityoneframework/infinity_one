defmodule UccChatWeb.Admin.Page.General do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks, Settings.General}

  def add_page do
    new("admin_general", __MODULE__, ~g(General), UccChatWeb.AdminView, "general.html", 60)
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: General.get() |> General.changeset()
        |> Hooks.all_users_post_filter,
    ], user, page, socket}
  end

end
