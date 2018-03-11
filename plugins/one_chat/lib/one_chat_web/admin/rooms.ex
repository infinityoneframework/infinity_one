defmodule OneChatWeb.Admin.Page.Rooms do
  use OneAdmin.Page

  import Ecto.Query
  import InfinityOneWeb.Gettext

  alias InfinityOne.{Repo, Hooks}
  alias OneChat.Schema.Channel, as: ChannelSchema

  require Logger

  def add_page do
    new(
      "admin_rooms",
      __MODULE__,
      ~g(Rooms),
      OneChatWeb.AdminView,
      "rooms.html",
      20,
      pre_render_check: &check_perissions/2,
      permission: "view-room-administration"
      )
  end

  def args(page, user, _sender, socket) do
    rooms = Repo.all(from c in ChannelSchema, order_by: [asc: c.name],
      preload: [:subscriptions, :messages])

    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      rooms: rooms,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-room-administration"
  end
end
