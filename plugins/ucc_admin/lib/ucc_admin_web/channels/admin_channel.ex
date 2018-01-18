defmodule UccAdminWeb.AdminChannel do

  import Rebel.Query, warn: false
  import Rebel.Core, warn: false

  alias UccAdminWeb.AdminView
  alias UccChatWeb.RebelChannel.{SideNav}

  require Logger

  def click_admin(socket, sender) do
    # Logger.debug inspect(sender)
    SideNav.open socket
    admin_link "admin_info", socket, sender
  end

  def admin_link(socket, sender) do
    # Logger.debug inspect(sender)
    admin_link sender["dataset"]["id"], socket, sender
  end

  def admin_link(id, socket, sender) do
    page = UccAdmin.get_page id
    {:noreply, apply(page.module, :open, [socket, sender, page])}
  end

  def admin_flex(socket, _sender) do
    # Logger.debug "sender: #{inspect sender}"
    {:noreply, socket}
  end

  # defp get_user!(%{assigns: %{user_id: user_id}}) do
  #   Accounts.get_user! user_id, preload: [:account, :roles]
  # end

  def render_to_string(templ, bindings \\ []) do
    Phoenix.View.render_to_string AdminView, templ, bindings
  end

end
