defmodule UccChatWeb.Admin.Page.Users do
  use UccAdmin.Page

  import Ecto.Query

  alias UcxUcc.{Repo, Hooks, Accounts.User}


  # alias UcxUcc.Repo
  # alias UccChat.{Message, Channel, UserService}

  def add_page do
    new("admin_users", __MODULE__, ~g(Users), UccChatWeb.AdminView, "users.html", 30)
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

end
