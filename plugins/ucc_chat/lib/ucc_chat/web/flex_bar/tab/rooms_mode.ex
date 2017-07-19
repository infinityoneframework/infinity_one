defmodule UccChat.Web.FlexBar.Tab.RoomsMode do
  use UccChat.Web.FlexBar.Helpers
  def add_buttons do
    TabBar.add_button %{
      groups: ~w[im],
      id: "rooms-mode",
      title: ~g"Rooms Mode",
      icon: "icon-hash",
      order: 2
    }
  end
end

