defmodule UccBackupRestoreWeb.FlexBar.Tab.GenCert do
  @moduledoc """
  Backup Certificates Flex Tab.
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
  alias UcxUccWeb.Query

  @roles_preload [:roles, user_roles: :role]

  @doc """
  Add the Certificates tab to the Flex Tabs list
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[admin_backup_restore],
      "admin_gen_cert",
      ~g"Certicicates",
      "icon-key",
      FlexBarView,
      "gen_cert.html",
      15,
      [
        model: Backup,
        prefix: "backup"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Certificates panel.
  """
  def args(socket, {user_id, channel_id, _, sender}, params) do
    current_user = Helpers.get_user! user_id
    {key, cert} = Utils.keys()

    {[
      keys_found: Utils.keys_exist?(),
      warning: false,
    ], socket}
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    Channel.flex_close(socket, sender)
  end

  @doc """
  Generate a new certificate.
  """
  def flex_form_save(socket, %{"form" => form} = sender) do
    {key, cert} = Utils.keys()

    Client.prepend_loading_animation(socket, ".content.gen-cert", :light_on_dark)

    with {_, 0} <- System.cmd("openssl", ~w(genrsa -out #{key} 2048)),
         {_, 0} <- System.cmd("openssl", ~w(rsa -in #{key} -out #{cert} -outform PEM -pubout)) do

      socket
      |> Channel.flex_close(sender)
      |> Client.toastr(:success, ~g(Certificate created successfully.))
    else
      {error, errno} ->
        Client.toastr(socket, :error, "Error #{errno}: #{error}")
    end

    Client.stop_loading_animation(socket)
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    Channel.flex_close(socket, sender)
  end

  @doc """
  Download the current certificate files.
  """
  def admin_download_cert(socket, _sender) do
    case Utils.download_cert(Utils.keys()) do
      {:ok, path} ->
        # Allow time for the download, then remove the tmp file
        spawn fn ->
          Process.sleep(10_000)
          File.rm path
        end

        download_path = String.trim_leading(path, Path.join(~w(priv static)))
        Client.download_cert(socket, download_path, "ucx_ucc_cert-#{Utils.datetime_now()}.tgz")

      {:error, error} ->
        Client.toastr(socket, :error, error)
    end
  end

  @doc """
  Handle the certificate regenerate button.
  """
  def admin_regen_cert(socket, sender) do
    unless Utils.backup_keys(Utils.keys()) == :ok do
      Client.toastr(socket, :warning, ~g(Problem creating backup of existing keys. They were not backed up.))
    end

    html = Phoenix.View.render_to_string(FlexBarView, "gen_cert.html", keys_found: false, warning: true)

    Query.update(socket, :html, set: html, on: "section.flex-tab-main")
  end

end

