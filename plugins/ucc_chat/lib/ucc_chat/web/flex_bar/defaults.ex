defmodule UccChat.Web.FlexBar.Defaults do
  use UcxUcc.Web.Gettext

  alias UcxUcc.TabBar

  def add_buttons do
    [StaredMessage, ImMode, RoomsMode, Mention, PinnedMessage,
     Notification, MembersList, Info, UserInfo]
    |> Enum.each(fn module ->
      UccChat.Web.FlexBar.Tab
      |> Module.concat(module)
      |> apply(:add_buttons, [])
    end)

    # TabBar.add_button %{
    #   groups: ~w(channel group direct im),
    #   id: "message-search",
    #   title: ~g"Search",
    #   icon: "icon-search",
    #   display: "hidden",
    #   view: View,
    #   template: "message_search.html",
    #   order: 20
    # }

  end
end
