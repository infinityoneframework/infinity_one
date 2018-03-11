defmodule OneAdmin.Hooks do
  use Unbrella.Hooks, :add_hooks

  alias OneAdmin.FlexBar.Defaults

  add_hook :add_flex_buttons, Defaults, :add_buttons

end
