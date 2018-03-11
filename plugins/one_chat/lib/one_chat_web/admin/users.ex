defmodule OneChatWeb.Admin.Page.Users do
  use OneAdmin.Page

  import Ecto.Query

  alias InfinityOne.{Repo, Hooks, Accounts.User}


  # alias InfinityOne.Repo
  # alias OneChat.{Message, Channel, UserService}

  def add_page do
    new(
      "admin_users",
      __MODULE__,
      ~g(Users),
      OneChatWeb.AdminView,
      "users.html",
      30,
      pre_render_check: &check_perissions/2,
      permission: "view-user-administration"
    )
  end

  def args(page, user, _sender, socket) do
    # Logger.warn "..."
    preload = Hooks.user_preload []
    user = Repo.preload user, preload

    users =
      (from u in User, order_by: [asc: u.username], preload: ^preload)
      |> Repo.all
      |> Hooks.all_users_post_filter

    {[
      user: user,
      users: users,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-user-administration"
  end
end
