defmodule UccBackupRestoreWeb.FlexBar.Tab.Upload do
  @moduledoc """
  Backup Upload Flex Tab.
  """
  use UccChatWeb.FlexBar.Helpers
  use UccLogger

  alias UcxUcc.{Accounts, TabBar.Tab, Permissions}
  alias UcxUcc.{TabBar, Hooks, UccPubSub}
  alias UccChat.ServiceHelpers
  alias UccBackupRestoreWeb.FlexBarView
  alias UccBackupRestore.Backup
  alias UccUiFlexTab.FlexTabChannel, as: Channel
  alias UccChatWeb.RebelChannel.Client
  alias UccBackupRestore.Utils

  @roles_preload [:roles, user_roles: :role]

  @doc """
  Add the Backup Upload tab to the Flex Tabs list
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_backup_restore],
      "admin_upload_backup",
      ~g"Upload",
      "icon-upload",
      FlexBarView,
      "upload.html",
      15,
      [
        model: Backup,
        prefix: "backup"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Upload panel.
  """
  def args(socket, {user_id, channel_id, _, sender}, params) do
    current_user = Helpers.get_user! user_id

    {[
      current_user: current_user,
      changeset: Backup.change(),
    ], socket}
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    socket
    |> Channel.flex_close(sender)
  end
end

