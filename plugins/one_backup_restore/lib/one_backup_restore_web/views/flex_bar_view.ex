defmodule OneBackupRestoreWeb.FlexBarView do
  @moduledoc """
  Backup and Restore plug-in Flex Tabs view.

  Renders the three Backup and Restore Tab panels:

  ## Backup Tab

  Allows the user to select which options to backup and creates the backup file.

  ## Certificates

  Displays page to generate certificate if one does not exist. Otherwise, displays
  page to download the certificates or generate a new one.

  ## Restore

  The Restore tab is displayed when the user clicks on the restore icon for a
  given backup. Allows the user to select which items to restore.
  """
  use OneBackupRestoreWeb, :view

  @doc false
  def certificates_download_instruction do
    [
      content_tag :p do
        ~g(
          Your certificates have been generated. Click the download button to
          download a backup copy to you PC. You will need to restore the certicicates in
          case of a server harddrive failure.)
      end,
      content_tag :p do
        ~g(Without these certificates, you will not be able to restore the encrypted database backup.)
      end,
      content_tag :p do
        ~g(
          You can also generate a new certificate using the Generate button below.
          However, the new certificate will not work with backups created with a previous
          certificate.)
      end
    ]
  end

  @doc false
  def replace_certificates_warning_message do
    content_tag :div, [class: "notice danger"] do
      [
        content_tag :p do
          ~g(You are about to replace the existing certificate with a new one.
             Database backups created with your existing certificate will not restore
             if you proceed with this action.)
        end,
        content_tag :p do
          ~g(Proceed only if you don't need any of the previous backups. It is recommended
             that the old backups be removed.)
        end,
        content_tag :p do
          ~g(Click the Cancel button below if you do not want to replace your existing
             certificate.)
        end
      ]
    end
  end
end
