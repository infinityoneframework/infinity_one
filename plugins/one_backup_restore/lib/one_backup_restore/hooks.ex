defmodule OneBackupRestore.Hooks do
  @moduledoc """
  A Hook implementation for the OneChat plugin.
  """
  use Unbrella.Hooks, :add_hooks

  alias OneBackupRestoreWeb.FlexBar.Defaults

  add_hook :register_admin_pages, OneBackupRestoreWeb.Admin, :add_pages
  add_hook :add_flex_buttons, Defaults, :add_buttons
end
