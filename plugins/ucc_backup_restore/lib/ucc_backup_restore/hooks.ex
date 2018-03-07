defmodule UccBackupRestore.Hooks do
  @moduledoc """
  A Hook implementation for the UccChat plugin.
  """
  use Unbrella.Hooks, :add_hooks

  alias UccBackupRestoreWeb.FlexBar.Defaults

  add_hook :register_admin_pages, UccBackupRestoreWeb.Admin, :add_pages
  add_hook :add_flex_buttons, Defaults, :add_buttons
end
