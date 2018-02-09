defmodule UccAdminWeb.AdminChannel do

  import Rebel.Query, warn: false
  import Rebel.Core, warn: false
  import UcxUccWeb.Gettext

  alias UccAdminWeb.AdminView
  alias UccChatWeb.RebelChannel.{SideNav}
  alias Rebel.SweetAlert

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

  def admin_restart_server(socket, _sender) do
    SweetAlert.swal_modal socket, ~g(Are you sure?),
      ~g(This will disrupt servic for all active users), "warning",
      [
        showCancelButton: true, closeOnConfirm: false, closeOnCancel: true,
        confirmButtonColor: "#DD6B55", confirmButtonText: ~g(Yes, restart it)
      ],
      confirm: fn _ ->
        {title, message, status} =
          case Application.get_env(:ucx_ucc, :restart_command) do
            [command | args] ->
              if System.find_executable(command) do
                try do
                  case System.cmd command, args do
                    {_, 0} ->
                      {~g"Restarting!", ~g"The server is being restarted!", "success"}
                    {error, code} ->
                      {gettext("Error %{code}", code: code), error , "error"}
                  end
                rescue
                  _ ->
                   {~g(Sorry), ~g(Something went wong), "error"}
                end
              else
                {~g(Sorry), ~g(The configured restart command cannot be found), "error"}
              end
            nil ->
              {~g(Sorry), ~g(The restart command is not configured!), "error"}

          end
        SweetAlert.swal(socket, title, message, status, timer: 5000, showConfirmButton: false)
      end
    socket
  end
end
