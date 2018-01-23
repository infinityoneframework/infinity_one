defmodule UccChatWeb.FlexBar.Defaults do
  use UcxUccWeb.Gettext

  alias UcxUcc.Hooks

  # alias UcxUcc.TabBar

  def add_buttons do
    [Search, StarredMessage, ImMode, RoomsMode, Mention, PinnedMessage,
     Notification, MembersList, Info, UserInfo, FilesList, RoomInfo]
    |> Enum.each(fn module ->
      UccChatWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)

    Hooks.add_flex_buttons

  end
end
