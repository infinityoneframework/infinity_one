defmodule UccAdminWeb.FlexBar.Tab.UserInfo do
  use UccLogger
  use UccChatWeb.FlexBar.Helpers

  alias UcxUcc.{TabBar, Hooks, Accounts}
  alias TabBar.Tab
  alias UccAdminWeb.FlexBarView
  # alias UcxUcc.TabBar.Ftab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_users],
      "admin_user_info",
      ~g"User Info",
      "icon-user",
      FlexBarView,
      "admin_edit_user.html",
      30)
  end

  def args(socket, {user_id, _channel_id, _other, sender}, params) do

    exec_js socket, set_active_js(sender)

    # Logger.error "sender: " <> inspect(sender)
    form = sender["form"] || %{}
    # Logger.error "id #{form["id"]}, form: " <> inspect(form)

    user =
      if name = sender["dataset"]["name"] || form["id"] do
        user = Accounts.get_by_user username: name, preload: Hooks.user_preload([])

        assigns =
          socket
          |> Rebel.get_assigns()
          |> Map.put(:user, user)
          |> Map.put(:resource_key, :user)

        Rebel.put_assigns(socket, assigns)
        user
      else
        nil
      end
    {[
      current_user: Helpers.get_user!(user_id),
      user: user,
    ], socket}
  end

  defp set_active_js(sender), do: """
   $('.flex-tab-main-content tr').removeClass('active');
   $('#{this(sender)}').addClass('active');
    """ |> String.replace("\n", "")

end
