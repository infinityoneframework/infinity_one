defmodule OneChatWeb.Admin.Page.Role do
  use OneAdmin.Page

  alias InfinityOne.{Repo, Hooks, Accounts, Permissions}
  alias Accounts.{Role}

  def add_page do
    new(
      "admin_role",
      __MODULE__,
      ~g(Role),
      OneChatWeb.AdminView,
      "role.html",
      41,
      visible: false,
      pre_render_check: &check_perissions/2,
      permission: "access-permissions"
    )
  end

  def args(page, user, %{"edit-name" => name}, socket) do
    preload = Hooks.user_preload []
    user = Repo.preload user, preload
    role = Accounts.get_by_role name: name, preload: [:users]

    {[
      user: user,
      changeset: Accounts.change_role(role),
    ], user, page, socket}
  end

  def args(page, user, _sender, socket) do
    preload = Hooks.user_preload []
    user = Repo.preload user, preload

    {[
      user: user,
      changeset: Accounts.change_role(),
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "access-permissions"
  end

  def scope_attrs(name) when is_binary(name) do
    if name in Role.default_role_names() do
      [disabled: true]
    else
      []
    end
  end
  def scope_attrs(_), do: []

  def get_permittion_role_changeset(role) do
    Permissions.change_permission_roles %{role_id: role.id}
  end
end
