defmodule UccChatWeb.FlexBar.Defaults do
  use UcxUccWeb.Gettext

  # alias UcxUcc.TabBar

  def add_buttons do
    [StaredMessage, ImMode, RoomsMode, Mention, PinnedMessage,
     Notification, MembersList, Info, UserInfo, FilesList]
    |> Enum.each(fn module ->
      UccChatWeb.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)

    UccWebrtcWeb.FlexBar.Tab.Webrtc.add_buttons

  end
end
