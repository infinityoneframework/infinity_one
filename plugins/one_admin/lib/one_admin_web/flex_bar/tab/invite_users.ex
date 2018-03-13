defmodule OneAdminWeb.FlexBar.Tab.InviteUsers do
  use OneLogger
  use OneChatWeb.FlexBar.Helpers

  alias InfinityOne.{Repo, TabBar}
  alias TabBar.Tab
  alias OneAdminWeb.FlexBarView
  alias OneAdmin.AdminService
  alias OneChatWeb.RebelChannel.Client
  alias InfinityOne.Coherence.Invitation
  # alias InfinityOne.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_invite_users",
      ~g"Inivite Users",
      "icon-paper-plane",
      FlexBarView,
      "admin_invite_users.html",
      10)
  end

    # html =
    #   "admin_invite_users.html"
    #   |> FlexBarView.render(user: current_user, channel_id: nil, user_info: %{admin: true},
    #      invite_emails: [], error_emails: [], pending_invitations: get_pending_invitations())
    #   |> safe_to_string
  def args(socket, {user_id, _channel_id, _, _}, _) do
    user = Helpers.get_user! user_id
    {[
      user: user,
      channel_id: nil,
      user_info: %{admin: true},
      error_emails: [],
      pending_invitations: AdminService.get_pending_invitations(),
      invite_emails: []], socket}
  end

  def invite_users(socket, sender) do
    Logger.info inspect(sender)
    socket
  end

  def delete_invitation(socket, sender) do
    id = sender["dataset"]["id"]
    email = sender["dataset"]["email"]

    Client.swal_modal(
      socket,
      ~g(Delete Invitation),
      gettext("Are you sure you want to delete %{name} invitation?", name: email),
      "warning",
      ~g(Delete Invitation!),
      confirm: fn _ ->
        case delete_invitation(id) do
          nil ->
            Client.swal socket, ~g(Error), ~g(Could not find that Invitation), "warning"
          {:ok, _} ->
            Client.swal socket, ~g(Succuss),
              gettext("%{name} invitation was deleted", name: email), "success"
            Client.slow_delete(socket, ~s/$('#{Rebel.Core.this(sender)}').closest('li')/)
        end
      end
    )

    socket
  end

  defp delete_invitation(id) do
    case Repo.get(Invitation, id) do
      nil -> nil
      invitation -> Repo.delete(invitation)
    end
  end
end
