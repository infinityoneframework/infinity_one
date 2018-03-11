defmodule OneAdmin.FlexBar.Defaults do
  use InfinityOneWeb.Gettext

  def add_buttons do
    [AddUser, InviteUsers, UserInfo]
    |> Enum.each(fn module ->
      OneAdminWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)
  end

end
