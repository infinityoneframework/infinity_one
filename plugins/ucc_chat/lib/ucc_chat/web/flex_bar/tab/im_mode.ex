defmodule UccChat.Web.FlexBar.Tab.ImMode do
  use UccChat.Web.FlexBar.Helpers

  alias UcxUcc.TabBar.Tab

  @spec add_buttons() :: any
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group direct],
      "im-mode",
      ~g"IM Mode",
      "icon-chat",
      View,
      "",
      1)
  end
end

