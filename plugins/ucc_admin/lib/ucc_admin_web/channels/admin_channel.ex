defmodule UccAdminWeb.AdminChannel do

  import Rebel.Query, warn: false
  import Rebel.Core, warn: false

  alias UcxUcc.Accounts
  alias UccAdmin.AdminService
  alias UccAdminWeb.AdminView
  alias UccChatWeb.RebelChannel.{NavMenu, SideNav}

  require Logger

  def click_admin(socket, sender) do
    user = get_user! socket
    Logger.warn "admin: user_id: #{user.id}, #{inspect sender}"
    main_content = AdminService.render_info(user) |> IO.inspect(label: "html")
    admin_flex = render_to_string("admin_flex.html", user: user) |> IO.inspect(label: "admin_flex")
    socket
    |> SideNav.open
    |> update(:html, set: main_content, on: ".main-content")
    |> update(:html, set: admin_flex, on: ".flex-nav section")
    {:noreply, socket}
  end

  defp get_user!(%{assigns: %{user_id: user_id}}) do
    Accounts.get_user! user_id, preload: [:account, :roles]
  end

  defp render_to_string(templ, bindings \\ []) do
    Phoenix.View.render_to_string AdminView, templ, bindings
  end

end
