defmodule OneChatWeb.FlexBar.Defaults do
  use InfinityOneWeb.Gettext

  alias InfinityOne.Hooks

  # alias InfinityOne.TabBar

  def add_buttons do
    # [Search, StarredMessage, ImMode, RoomsMode, Mention, PinnedMessage,
    [Search, StarredMessage, RoomsMode, Mention, PinnedMessage,
     Notification, MembersList, Info, UserInfo, FilesList, RoomInfo]
    |> Enum.each(fn module ->
      OneChatWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)

    Hooks.add_flex_buttons

  end
end
