defmodule UccAdmin.FlexBar.Defaults do
  use UcxUccWeb.Gettext

  def add_buttons do
    [AddUser, InviteUsers, UserInfo]
    |> Enum.each(fn module ->
      UccAdminWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)
  end

end
