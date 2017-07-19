defmodule UccChat.Web.FlexBar.Tab.ImMode do
  use UccChat.Web.FlexBar.Helpers

  def add_buttons do
    TabBar.add_button %{
      groups: ~w[channel group direct],
      id: "im-mode",
      title: ~g"IM Mode",
      icon: "icon-chat",
      order: 1
    }
  end
end

