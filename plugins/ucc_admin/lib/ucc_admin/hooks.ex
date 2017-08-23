defmodule UccAdmin.Hooks do
  use Unbrella.Hooks, :add_hooks

  alias UccAdmin.FlexBar.Defaults

  add_hook :add_flex_buttons, Defaults, :add_buttons

end
