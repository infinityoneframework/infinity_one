defmodule OneChatWeb.Admin.Page.PhoneNumbers do
  use OneAdmin.Page

  # import Ecto.Query
  import InfinityOneWeb.Gettext

  # alias InfinityOne.Repo
  alias InfinityOne.{Accounts, Repo, Hooks}

  require Logger

  def add_page do
    new(
      "admin_phone_numbers",
      __MODULE__,
      ~g(Phone Numbers),
      OneChatWeb.AdminView,
      "phone_numbers.html",
      41,
      pre_render_check: &check_perissions/2,
      permission: "view-phone-numbers-administration"
    )
  end

  def args(page, user, _sender, socket) do
    labels = Accounts.list_phone_number_labels()

    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      labels: labels
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-phone-numbers-administration"
  end
end
