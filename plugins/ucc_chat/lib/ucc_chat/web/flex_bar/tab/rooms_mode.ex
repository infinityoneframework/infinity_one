defmodule UccChat.Web.FlexBar.Tab.RoomsMode do
  use UccChat.Web.FlexBar.Helpers

  alias UcxUcc.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[im],
      "rooms-mode",
      ~g"Rooms Mode",
      "icon-hash",
      View,
      "",
      2)
  end
end

