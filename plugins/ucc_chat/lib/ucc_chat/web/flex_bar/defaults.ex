defmodule UccChat.Web.FlexBar.Defaults do
  use UcxUcc.Web.Gettext

  # alias UcxUcc.TabBar

  def add_buttons do
    [StaredMessage, ImMode, RoomsMode, Mention, PinnedMessage,
     Notification, MembersList, Info, UserInfo, FilesList]
    |> Enum.each(fn module ->
      UccChat.Web.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)

  end
end
