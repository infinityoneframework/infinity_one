defmodule UccChatWeb.ChannelController do
  use UccChatWeb, :controller
  use Rebel.Controller, channels: [
    UccChatWeb.UserChannel,
    UccChatWeb.RoomChannel,
  ] ++ UcxUcc.Hooks.ucc_chat_channel_controller_channels([])

  import Ecto.Query

  require Logger

  alias UccChat.{ChatDat}
  alias UccChat.{Message, Channel, ChannelService}
  alias UcxUcc.{Accounts.User, Hooks}
  alias UccChat.Schema.Channel, as: ChannelSchema
  alias UccChat.Schema.Direct, as: DirectSchema

  plug :put_user_id_session
  plug :put_user_peer

  def put_user_peer(conn, _) do
    put_session conn, :user_peer, conn.peer
  end

  def put_user_id_session(conn, _) do
    current_user = Coherence.current_user conn
    put_session conn, :current_user_id, current_user.id
  end

  def index(conn, _params) do
    case Coherence.current_user(conn) do
      nil ->
        UcxUccWeb.Coherence.SessionController.delete(conn, %{})
      user ->
        channel = if user.open_id do
          Logger.debug "index load open id"
          case Channel.get(user.open_id) do
            nil ->
              Channel.list() |> hd
            channel ->
              channel
          end
        else
          Logger.debug "index load no open id"
          channel =
            ChannelSchema
            |> Ecto.Query.first
            |> Repo.one

          user
          |> User.changeset(%{open_id: channel.id})
          |> Repo.update!
          channel
        end

        show(conn, channel)
    end
  end

  def show(conn, %ChannelSchema{} = channel) do
    user =
      conn
      |> Coherence.current_user
      |> Hooks.preload_user([:account])

    UccChat.PresenceAgent.load user.id

    page = Message.get_room_messages(channel.id, user)

    chatd =
      user
      |> ChatDat.new(channel, page)
      |> ChatDat.get_messages_info

    conn
    |> put_view(UccChatWeb.MasterView)
    |> put_layout({UcxUccWeb.LayoutView, "app.html"})
    |> render("main.html", chatd: chatd)
  end

  def show(conn, %{"name" => name}) do
    case Channel.get_by(name: name) do
      nil ->
        conn
        |> put_flash(:error, "#{name} is an invalid channel name!")
        |> redirect(to: "/")
      channel ->
        if channel.type in [0,1] do
          show(conn, channel)
        else
          redirect(conn, do: "/")
        end
    end
  end

  def direct(conn, %{"name" => name}) do
    with user when not is_nil(user) <- UccChat.ServiceHelpers.get_user_by_name(name),
         user_id <- Coherence.current_user(conn) |> Map.get(:id),
         false <- user.id == user_id do

      case get_direct(user_id, name) do
        nil ->
          # create the direct and redirect
          ChannelService.add_direct(name, user_id, nil) #  |> IO.inspect(label: "direct")
          direct = get_direct(user_id, name) #|> IO.inspect(label: "direct 1")
          show(conn, direct.channel)
        direct ->
          show(conn, direct.channel)
      end
    else
      _ -> redirect conn, to: "/"
    end
  end

  def get_direct(user_id, name) do
    (from d in DirectSchema,
      # where: d.user_id == ^user_id and like(d.users, ^"#{name}__%") or like(d.users, ^"%__#{name}")),
      where: d.user_id == ^user_id and d.users == ^name,
      preload: [:channel])
    |> Repo.one
  end

  def page(conn, params) do
    Logger.debug "page action"
    # _page_name = params["page"] || "home"

    # user =
    #   conn
    #   |> Coherence.current_user
    #   |> Hooks.preload_user([:account])

    # UccChat.PresenceAgent.load user.id
    UccChatWeb.HomeController.index(conn, params)
  end

end
