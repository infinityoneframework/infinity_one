defmodule UccChatWeb.Admin.Page.Rooms do
  use UccAdmin.Page

  import Ecto.Query
  import UcxUccWeb.Gettext

  alias UcxUcc.Repo
  alias UccChat.Schema.Channel, as: ChannelSchema

  require Logger

  def add_page do
    new("admin_rooms", __MODULE__, ~g(Rooms), UccChatWeb.AdminView, "rooms.html", 20)
  end

  def args(page, user, _sender, socket) do
    rooms = Repo.all(from c in ChannelSchema, order_by: [asc: c.name],
      preload: [:subscriptions, :messages])

    {[
      user: user,
      rooms: rooms,
    ], user, page, socket}
  end

end
