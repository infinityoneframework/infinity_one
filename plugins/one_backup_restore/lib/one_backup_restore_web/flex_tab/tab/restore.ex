defmodule OneBackupRestoreWeb.FlexBar.Tab.Restore do
  @moduledoc """
  Backup Restore Flex Tab.
  """
  use OneChatWeb.FlexBar.Helpers
  use OneLogger

  alias InfinityOne.{TabBar.Tab}
  alias InfinityOne.{TabBar}
  alias OneChat.ServiceHelpers
  alias OneBackupRestoreWeb.FlexBarView
  alias OneBackupRestore.Backup
  alias OneUiFlexTab.FlexTabChannel, as: Channel
  alias OneChatWeb.RebelChannel.Client
  alias OneBackupRestore.Utils

  require Logger

  @doc """
  Add the Restore tab to the Flex Tabs list
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_backup_restore],
      "admin_restore",
      ~g"Restore",
      "icon-ccw",
      FlexBarView,
      "restore.html",
      20,
      [
        model: Backup,
        prefix: "backup"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Restore panel.
  """
  def args(socket, {user_id, _channel_id, _, sender}, _params) do
    current_user = Helpers.get_user! user_id

    name = sender["dataset"]["name"] |> IO.inspect(label: "name")

    # Rebel.Core.async_js(socket, ~s/$('.tab-button[data-id="admin_restore"]').removeClass('hidden')/)
    {[
      opts: get_opts(name),
      name: name,
      current_user: current_user,
      changeset: Backup.change(),
    ], socket}
  end

  @doc """
  Perform a Restore.
  """
  def flex_form_save(socket, %{"form" => form} = sender) do

    resource_params = ServiceHelpers.normalize_params(form)["backup"] || %{}

    name = sender["form"]["file-name"]

    params =
      for {key, val} <- resource_params, into: %{} do
        {String.to_existing_atom(key), val == "1"}
      end

    restore_params = Map.put(params, :backup_name, name)

    Client.prepend_loading_animation(socket, ".content.restore", :light_on_dark)

    case restore_backup(restore_params, name && Enum.any?(params, &elem(&1, 1))) do
      {:ok, name} ->
        socket
        |> Client.stop_loading_animation()
        |> Channel.flex_close(sender)
        |> async_js(~s/$('a.admin-link[data-id="admin_backup_restore"]').click()/)
        |> Client.toastr(:success, gettext("Backup %{name} restored successfully!", name: name))

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
        |> Client.toastr(:error, ~g(Must select at least one restore option!))
    end
    socket
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    socket
    |> Channel.flex_close(sender)
  end

  defp restore_backup(_params, false), do: false

  defp restore_backup(params, _) do
    case OneBackupRestore.restore(params) do
      %{error?: false} ->
        {:ok, ""}
      %{errors: errors} ->
        {:error, errors}
    end
  end

  defp get_opts(nil), do: %{}

  defp get_opts(name) do
    case Utils.untar_backup(name) do
      {:ok, %{path: path, contents: contents}} ->
        # Only need the ls contents  now, so we can remove the temp dir
        File.rm_rf(path)

        %{
          database: Enum.any?(contents, & &1 =~ ".backup"),
          configuration: Enum.any?(contents, & &1 =~ ".conf"),
          attachments: Enum.any?(contents, & &1 =~ "uploads"),
          avatars: Enum.any?(contents, & &1 =~ "avatars"),
          sounds: Enum.any?(contents, & &1 =~ "sounds"),
        }

      _ ->
        %{
          database: false,
          configuration: false,
          attachments: false,
          avatars: false,
          sounds: false,
        }
    end
  end

end
