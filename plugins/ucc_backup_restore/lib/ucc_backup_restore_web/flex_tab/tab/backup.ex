defmodule UccBackupRestoreWeb.FlexBar.Tab.Backup do
  @moduledoc """
  Admin Backup Flex Tab.
  """
  use UccChatWeb.FlexBar.Helpers
  use UccLogger

  alias UcxUcc.{Accounts, TabBar.Tab, Permissions}
  alias UcxUcc.{TabBar, Hooks, UccPubSub}
  alias UccChat.ServiceHelpers
  alias UccBackupRestoreWeb.FlexBarView
  alias UccBackupRestore.{Utils, Backup}
  alias UccUiFlexTab.FlexTabChannel, as: Channel
  alias UccChatWeb.RebelChannel.Client

  @roles_preload [:roles, user_roles: :role]

  @doc """
  Add the Backup tab to the Flex Tabs list
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_backup_restore],
      "admin_backup",
      ~g"Backup",
      "icon-database",
      FlexBarView,
      "backup.html",
      10,
      [
        model: Backup,
        prefix: "backup"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Backup panel.
  """
  def args(socket, {user_id, channel_id, _, _,}, params) do
    current_user = Helpers.get_user! user_id
    opts = get_opts()

    unless opts[:database] do
      Client.toastr(socket,
        :warning, ~g(Certificate must be generated before backing up the database.))
    end

    {[
      current_user: current_user,
      changeset: Backup.change(),
      opts: opts,
    ], socket}
  end

  @doc """
  Perform a backup
  """
  def flex_form_save(socket, %{"form" => %{"flex-id" => tab_name} = form} = sender) do
    tab = TabBar.get_button tab_name

    resource_params = ServiceHelpers.normalize_params(form)["backup"] || %{}

    params =
      for {key, val} <- resource_params, into: %{} do
        {String.to_existing_atom(key), val == "1"}
      end

    Client.prepend_loading_animation(socket, ".content.backup", :light_on_dark)

    case create_backup(params, Enum.any?(params, &elem(&1, 1))) do
      {:ok, name} ->
        socket
        |> Client.stop_loading_animation()
        |> Channel.flex_close(sender)
        |> async_js(~s/$('a.admin-link[data-id="admin_backup_restore"]').click()/)
        |> Client.toastr(:success, gettext("Backup %{name} created successfully!", name: name))

      {:error, message} when is_binary(message) ->
        socket
        |> Client.stop_loading_animation()
        |> Client.toastr(:error, message)

      {:error, message} ->
        socket
        |> Client.stop_loading_animation()
        |> Client.toastr(:error, inspect(message))

      false ->
        socket
        |> Client.stop_loading_animation()
        |> Client.toastr(:error, ~g(Must select at least one backup option!))
    end
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    Channel.flex_close(socket, sender)
  end

  defp create_backup(_params, false), do: false

  defp create_backup(params, _) do
    case UccBackupRestore.backup params do
      %{error?: false} ->
        {:ok, "mybackup.tgz"}
      %{errors: errors} ->
        {:error, errors}
    end
  end

  def get_opts do
    %{
      database: Utils.keys_exist?(),
      configuration: Utils.conf_file_exists?(),
      avatars: true,
      sounds: true,
      attachments: true
    }
  end

end
