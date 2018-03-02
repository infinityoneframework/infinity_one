defmodule UccBackupRestoreWeb.Admin.Page.BackupRestore do
  @moduledoc """
  Backup and Restore plug-in Admin page.
  """
  use UccAdmin.Page

  import UcxUccWeb.Gettext

  alias UcxUcc.{Repo, Hooks, Settings.Accounts}
  alias UccChatWeb.RebelChannel.Client
  alias UccBackupRestore.Utils
  alias UccChat.ServiceHelpers

  require Logger

  def add_page do
    new(
      "admin_backup_restore",
      __MODULE__,
      ~g(Backup and Restore),
      UccBackupRestoreWeb.AdminView,
      "backup_restore.html",
      53
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      backups: UccBackupRestore.get_backups()
    ], user, page, socket}
  end

  def admin_restore_backup(socket, sender) do
    socket
  end

  def admin_delete_backup(socket, sender) do
    id = sender["dataset"]["id"]
    Client.swal_modal(
      socket,
      ~g(Delete Backup),
      gettext("Are you sure do delete %{id}? This cannot be undone!", id: id),
      "warning",
      ~g(Delete Backup!),
        confirm: fn result ->
          {title, text, type} =
            case Utils.delete_backup(id) do
              {:error, message} ->
                {
                  ~g(Oops, something went wrong!),
                  gettext("Error: %{message}.", message: message),
                  "error"
                }
              _ ->
                {
                  ~g(Success!),
                  ~g(Backup file removed successfully),
                  "success"
                }
            end
          Client.swal(socket, title, text, type)
          if type == "success" do
            remove_row(socket, id)
          end
          socket
        end
      )
    socket
  end

  def admin_backup_batch_delete(socket, %{"form" => form} = sender) do
    params = ServiceHelpers.normalize_params(form)["backup"] || %{}

    backups =
      params
      |> Enum.filter(& elem(&1, 1) == "true")
      |> Enum.map(& elem(&1, 0))

    Client.swal_modal(
      socket,
      ~g(Delete Backups),
      ~g(Are you sure you want to delete the selected backups? This cannot be undone!),
      "warning",
      ~g(Delete Backups!),
      confirm: fn _ ->
        case Utils.batch_delete_backups(backups) do
          {:ok, list} ->
            Client.swal(socket, ~g(Success!), ~g(Backup files removed successfully), "success")
            list
          {:error, list} ->
            Client.swal(socket, ~g(Error!), ~g(One or more of the files wern't removed), "error")
            list
        end
        |> Enum.each(&remove_named_row(socket, &1))
        Rebel.Core.async_js(socket, ~s/$('#batch-delete').attr('disabled', true)/)
      end
    )
    socket
  end

  defp remove_row(socket, id) do
    spawn fn ->
      name = Path.rootname(id)
      js = """
        var target = $('[download="#{name}"]').closest('tr');
        target.hide('slow', function() { target.remove(); });
        """ |> String.replace("\n", "")
      Rebel.Core.async_js(socket, js)
    end
    socket
  end

  defp remove_named_row(socket, name) do
    spawn fn ->
      js = """
        var target = $('[name="backup[#{name}]"]').closest('tr');
        target.hide('slow', function() { target.remove(); });
        """ |> String.replace("\n", "")
      Rebel.Core.async_js(socket, js)
    end
  end
end
