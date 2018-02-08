defmodule UccChat.ChannelService do
  @moduledoc """
  Helper functions used by the controller, channel, and model for Channels
  """
  use UccChat.Shared, :service

  # import Phoenix.HTML.Tag, only: [content_tag: 2]
  import Ecto.Query
  import UccChat.NotifierService

  alias UccChat.Schema.Channel, as: ChannelSchema

  # alias UccChat.{
  #   Channel, Subscription, MessageService, UserService,
  #   ChatDat, Direct, Mute, SideNavService, Message, Settings
  # }
  alias UccChat.{
    Channel, Subscription, UserService,
    ChatDat, Direct, Mute, SideNavService, Message
  }
  alias UcxUcc.Repo
  alias UcxUcc.Accounts.{User, UserRole}
  alias UcxUcc.Permissions
  alias UccChat.ServiceHelpers, as: Helpers
  alias Ecto.Multi
  alias UcxUcc.{Hooks, Accounts}
  alias UccChatWeb.RoomChannel.Channel, as: WebChannel
  alias UccChatWeb.RoomChannel.Message, as: WebMessage

  alias UccUiFlexTabWeb.TabBarView

  require UccChat.ChatConstants, as: CC
  require Logger
  require IEx

  # @public_channel  0
  # @private_channel 1
  # @direct_message  2
  # @starred_room     3

    # # def can_view_room?(channel, user) do
    # #   cond do
    # #     channel.type == 0 and Permissions.has_permission?(user, "post-readonly", assigns.channel_id) ->
    # #   end
    # # end
    # def create_subscription(%ChannelSchema{} = channel, user_id) do
    #   case Subscription.create(%{user_id: user_id, channel_id: channel.id}) do
    #     {:ok, _} = ok ->
    #       UccPubSub.broadcast "user:" <> user_id, "new:subscription",
    #         %{channel_id: channel.id}
    #       ok
    #     other ->
    #       other
    #   end
    # end

  # @doc """
  # Create a channel subscription

  # Creates the subscription but does not account the join
  # """
  # def create_subscription(channel_id, user_id) do
  #   channel_id
  #   |> Channel.get!
  #   |> WebChannel.join(user_id)
  # end

  @doc """
  Create a channel subscription and announce the join if configured.
  """
  def join_channel(channel, user_id, opts \\ [])
  def join_channel(%ChannelSchema{} = channel, user_id, _opts) do
    WebChannel.join channel, user_id
  end
  def join_channel(channel_id, user_id, opts) do
    channel_id
    |> Channel.get!
    |> join_channel(user_id, opts)
  end

  # def room_type(:public), do: @public_channel
  # def room_type(:private), do: @private_channel
  # def room_type(:direct), do: @direct_message
  # def room_type(:starred), do: @starred_room

  def set_subscription_state(channel, user_id, state)
    when state in [true, false] do
    attrs = if state == true, do: %{open: true, hidden: false}, else: %{open: state}
    case Subscription.get_by channel_id: channel, user_id: user_id do
      nil -> nil
      sub -> Subscription.update(sub, attrs)
    end
  end

  def set_subscription_state_room(name, user_id, state)
    when state in [true, false] do
    attrs = if state == true, do: %{open: true, hidden: false}, else: %{open: state}
    case Subscription.get_by_room(name, user_id) do
      nil -> nil
      sub -> Subscription.update(sub, attrs)
    end
  end

  def get_unread(channel_id, user_id) do
    Logger.warn "deprecated"
    case Subscription.get_by channel_id: channel_id, user_id: user_id do
      nil -> 0
      sub -> sub.unread
    end
  end

  def set_has_unread(channel_id, user_id, false) do
    Logger.warn "deprecated"
    clear_unread(channel_id, user_id)
  end

  def set_has_unread(channel_id, user_id, value) do
    Logger.warn "deprecated"
    [channel_id: channel_id, user_id: user_id]
    |> Subscription.get_by
    |> case do
      nil -> nil
      sub -> Subscription.update(sub, %{has_unread: value})
    end
  end
  # def set_has_unread(channel_id, user_id, value \\ true) do
  #   case Subscription.get(channel_id, user_id) |> Repo.one do
  #     nil ->
  #       {:error, :not_found}
  #     subs ->
  #       subs
  #       |> Subscription.changeset(%{has_unread: value})
  #       |> Repo.update
  #   end
  # end


  def clear_unread(channel_id, user_id) do
    case Subscription.get_by channel_id: channel_id, user_id: user_id do
      nil -> nil
      sub -> Subscription.update(sub, %{unread: 0, has_unread: false})
    end
  end

  def increment_unread(channel_id, user_id) do
    with sub when not is_nil(sub) <- Subscription.get_by(
      channel_id: channel_id, user_id: user_id),
         unread <- sub.unread + 1,
         {:ok, _} <- Subscription.update(sub, %{unread: unread}) do
      unread
    else
      _ -> 0
    end
  end

  def get_has_unread(channel_id, user_id) do
    case Subscription.get_by(channel_id: channel_id, user_id: user_id) do
      nil ->
        raise "Subscription for channel: #{channel_id}, " <>
          "user: #{user_id} not found"
      %{has_unread: unread} ->
        unread
    end
  end

  def room_type(0), do: :public
  def room_type(1), do: :private
  def room_type(2), do: :direct
  def room_type(3), do: :starred

  def room_type(:public), do: 0
  def room_type(:private), do: 1
  def room_type(:direct), do: 2
  def room_type(:starred), do: 3

  def base_types do
    [:starred, :public, :direct]
    |> Enum.map(&(%{type: &1, can_show_room: true,
      template_name: get_templ(&1), rooms: []}))
  end

  def side_nav_where(%User{account: %{chat_mode: true}}, user_id, opts) do
    Subscription.get_by_user_id_and_types(user_id, [2, 3], opts)
  end

  def side_nav_where(_user, user_id, opts) do
    Subscription.get_by_user_id user_id, opts
  end

  ##################
  # Repo Multi

  def insert_channel!(%{user_id: user_id} = params) do
    user_id
    |> Helpers.get_user!(preload: [:roles, user_roles: :role])
    |> insert_channel!(params)
  end

  def insert_channel!(user, params) do
    case insert_channel user, params do
      {:ok, channel} -> channel
      cs -> raise "insert channel failed: #{inspect cs}"
    end
  end

  def insert_channel(%{user_id: user_id} = params) do
    user = Helpers.get_user!(user_id, preload: [:roles, user_roles: :role])
    insert_channel(user, params)
  end

  def insert_channel(user, params) do
    multi =
      Multi.new
      |> Multi.insert(:channel, Channel.changeset(user, params))
      |> Multi.run(:roles, &do_roles/1)

    case Repo.transaction(multi) do
      %{channel: channel}        -> {:ok, channel}
      {:ok, %{channel: channel}} -> {:ok, channel}
      error                      -> error
    end
  end

  def delete_channel(socket, room, _user_id) do
    with channel when not is_nil(channel) <- Channel.get_by(name: room),
         changeset <- Channel.changeset_delete(channel),
         {:ok, _} <- Repo.delete(changeset) do
      # Logger.debug "deleting room #{room}"
      Phoenix.Channel.broadcast socket, "room:delete",
        %{room: room, channel_id: channel.id}
      Phoenix.Channel.broadcast socket, "reload", %{location: "/"}
      {:ok, %{success: ~g"The room has been deleted", reload: true}}
    else
      _ ->
        {:error, %{error: ~g"Problem deleting the channel"}}
    end
  end

  def do_roles(%{channel: %{id: _ch_id, user_id: u_id} = channel}) do
    role = UcxUcc.Accounts.get_role_by_name("owner") ||
      raise("owner role required")
    # TODO: The scope concept of user_role is broken.
    %{user_id: u_id, role_id: role.id}
    |> UcxUcc.Accounts.create_user_role() #, scope: "global"})
    |> case do
      {:ok, _} -> {:ok, channel}
      error -> error
    end
  end

  # TODO: Do we need to implement this?
  def add_moderator(_channel, _user_id) do
    Logger.error "add_moderator not implemented"
  end

  ##################
  #

  def get_side_nav_rooms_search(%User{} = user, pattern, opts \\ []) do
    pattern =
      if opts[:fuzzy] do
        pattern
        |> String.to_charlist
        |> Enum.intersperse("%")
        |> to_string
      else
        pattern
      end

    user.id
    |> Channel.get_channels_by_pattern("%" <> pattern <> "%", 1000)
    |> order_by([c], [asc: c.name])
    |> Repo.all
  end

  def get_side_nav_rooms(%User{} = user) do
    user
    |> Channel.get_all_channels
    |> order_by([c], [asc: c.name])
    |> Repo.all
  end

  def build_active_room(%ChannelSchema{} = channel) do
    %{
      active: true,
      alert: false,
      archived: channel.archived,
      can_leave: false,
      channel_id: channel.id,
      channel_type: channel.type,
      display_name: channel.name,
      hidden: false,
      name: channel.name,
      room_icon: get_icon(channel.type),
      type: room_type(channel.type),
      unread: false,
      user_status: "offline"
    }
  end

  def unhide_current_channel(%{channel_id: channel_id} = cc, channel_id) do
    # Logger.debug "unhiding channel name: #{inspect cc.channel.name}"
    unhide_subscription(cc)
  end
  def unhide_current_channel(cc, _channel_id), do: cc

  def get_side_nav_search(user, match, channel_id, opts \\ [])
  def get_side_nav_search(%User{} = user, match, channel_id, opts) do
    channel = get_channel channel_id
    rooms = side_nav_search(user, match, channel, opts)
    %{
      room_types: rooms |> all_room_types() |> room_types(false),
      room_map: room_map(rooms),
      rooms: [],
      active_room: Enum.find(rooms, &(&1[:open])) || build_active_room(channel),
      search_empty: rooms == [],
    }
  end

  def get_side_nav_search(user_id, match, channel_id, opts) do
    user_id
    |> Accounts.get_user(preload: [:account, :roles, user_roles: [:role]])
    |> get_side_nav_search(match, channel_id, opts)
  end

  @doc """
  Get the side_nav data used in the side_nav templates
  """
  # def get_side_nav(%User{id: id}, channel_id), do: get_side_nav(id, channel_id)
  def get_side_nav(%User{id: _id} = user, channel_id) do
    channel = get_channel channel_id
    chat_mode = user.account.chat_mode
    rooms = side_nav_rooms user, channel, channel_id, chat_mode

    %{
      room_types: rooms |> all_room_types() |> room_types(chat_mode),
      room_map: room_map(rooms),
      rooms: [],
      active_room: Enum.find(rooms, &(&1[:open])) || build_active_room(channel)
    }
  end

  defp channel_room(cc, id, _channel, channel_id) do
    chan = cc.channel
    open = chan.id == channel_id
    type = get_chan_type(cc.type, chan.type)
    {display_name, user_status, user} =
      get_channel_display_name(type, chan, id)
    unread = if cc.unread == 0, do: false, else: cc.unread
    # cc = unhide_current_channel(cc, channel_id)
    status_message =
      if chan.type == 2 and user.account.status_message != "",
        do: user.account.status_message, else: nil

    %{
      open: open,
      status_message: status_message,
      has_unread: cc.has_unread,
      unread: unread,
      alert: cc.alert,
      user_status: user_status,
      can_leave: chan.type != 2,
      archived: false,
      name: chan.name,
      hidden: cc.hidden,
      room_icon: get_icon(chan.type),
      channel_id: chan.id,
      channel_type: chan.type,
      type: type,
      display_name: display_name,
      active: chan.active,
      last_read: cc.last_read,
      user: user
    }
    |> Hooks.build_sidenav_room()
  end

  defp side_nav_search(user, match, channel, opts) do
    match
    |> run_search(user.id, opts[:fuzzy])
    |> Enum.map(fn cc -> channel_room(cc, user.id, channel, channel.id) end)
    |> Enum.sort(fn a, b ->
      String.downcase(a.display_name) < String.downcase(b.display_name)
    end)
  end

  defp run_search(match, user_id, true),  do: Subscription.fuzzy_search(match, user_id)
  defp run_search(match, user_id, _),  do: Subscription.search(match, user_id)

  defp side_nav_rooms(user, channel, channel_id, chat_mode) do
    user
    |> side_nav_where(user.id, preload: [:channel])
    |> Enum.map(fn cc -> channel_room(cc, user.id, channel, channel_id) end)
    |> Enum.filter(&(&1.active))
    |> Enum.sort(fn a, b ->
      String.downcase(a.display_name) < String.downcase(b.display_name)
    end)
    |> Enum.reject(fn %{channel_type: chan_type, hidden: hidden} ->
      chat_mode && (chan_type in [0,1]) or hidden
    end)
  end

  defp get_channel(nil), do: Channel.new
  defp get_channel(id), do: Channel.get(id) || Channel.new

  defp all_room_types(rooms) do
    rooms
    |> Enum.group_by(fn item ->
      case Map.get(item, :type) do
        :private -> :public
        other -> other
      end
    end)
    |> Enum.reduce(%{}, fn {type, list}, acc ->
      map = %{
        type: type,
        can_show_room: true,  # this needs to be based on permissions
        template_name: get_templ(type),
        rooms: list,
      }
      put_in acc, [type], map
    end)
  end

  defp room_types(room_types, chat_mode) do
    base_types()
    |> Enum.reject(fn %{type: type} -> type == :public && chat_mode end)
    |> Enum.map(fn %{type: type} = bt ->
      case room_types[type] do
        nil -> bt
        other -> other
      end
    end)
  end

  defp room_map(rooms) do
    Enum.reduce rooms, %{}, fn room, acc ->
      put_in acc, [room[:channel_id]], room
    end
  end

  def get_channel_display_name(type, %ChannelSchema{id: id, name: name},
    user_id) when type == :direct or type == :starred do

    case Direct.get_by channel_id: id, user_id: user_id, preload: [:friend] do
      %{} = direct ->
        friend =
          direct.friend
          |> Hooks.preload_user([:account])
        {friend.username, UccChat.PresenceAgent.get(friend.id), friend}
      _ ->
        {name, "offline", nil}
    end
  end
  def get_channel_display_name(_, %ChannelSchema{name: name}, _) do
    {name, "offline", nil}
  end

  def favorite_room?(%{} = chatd, channel_id) do
    with room_types <- chatd.rooms,
         starred when not is_nil(starred) <-
            Enum.find(room_types, &(&1[:type] == :starred)),
         room when not is_nil(room) <-
           Enum.find(starred, &(&1[:channel_id] == channel_id)) do
      true
    else
      _ -> false
    end
  end

  def favorite_room?(user_id, channel_id) do
    {cc, _user} = get_subscription_and_user(user_id, channel_id)
    cc.type == room_type(:starred)
  end

  def get_chan_type(3, _), do: :starred
  def get_chan_type(_, type), do: room_type(type)

  def room_redirect(room, display_name) do
    channel = Channel.get_by! name: room
    "/" <> Channel.room_route(channel) <> "/" <> display_name
  end

  defp unhide_subscription(subscription) do
    Subscription.update!(subscription, %{hidden: false})
  end

  def open_room(user_id, room, old_room, display_name) do
    Logger.debug fn -> "open_room room: #{inspect room}, old_room: #{inspect old_room}" end
    # Logger.warn "ChannelService.open_room room: #{inspect room}, display_name: #{inspect display_name}"
    user = Helpers.get_user!(user_id)

    opens = UserService.open_channels(user_id)

    if UserService.open_channel_count(user_id) > 1 do
      Logger.error "found more than one open, opens: #{inspect opens}"

      opens
      |> Enum.reject(&(&1.name == old_room))
      |> Enum.each(fn channel ->
        Logger.warn "force close room #{channel.name}"
        set_subscription_state_room(channel.name, user_id, false)
      end)
    end

    channel = Channel.get_by! name: room, preload: [:subscriptions]

    old_channel =
      if old_room do
        set_subscription_state_room(old_room, user_id, false)
        Channel.get_by! name: old_room
      else
        %{type: nil}
      end

    set_subscription_state(channel.id, user_id, true)

    user
    |> User.changeset(%{open_id: channel.id})
    |> Repo.update!

    page = Message.get_room_messages(channel.id, user)

    chatd =
      user
      |> ChatDat.new(channel, page)
      |> ChatDat.get_messages_info(user)

    Logger.debug fn -> "messages_info: #{inspect chatd.messages_info}" end

    html = Phoenix.View.render_to_string(UccChatWeb.MasterView,
      "messages_container.html", chatd: chatd)

    side_nav_html = SideNavService.render_rooms_list(channel.id, user_id)

    %{
      display_name: display_name,
      room_title: room,
      channel_id: channel.id,
      html: html,
      messages_info: chatd.messages_info,
      allow_upload: UccChat.AttachmentService.allowed?(channel),
      side_nav_html: side_nav_html,
      room_route: Channel.room_route(channel)
    }
    |> set_flex_html(channel.type, old_channel.type)
  end

  defp set_flex_html(map, type, type) do
    map
  end
  defp set_flex_html(map, 2, _) do
    Map.put map, :flex_html, Phoenix.View.render_to_string(TabBarView, "tab_bar.html", groups: ["direct"])
  end
  defp set_flex_html(map, _, _) do
    Map.put map, :flex_html, Phoenix.View.render_to_string(TabBarView, "tab_bar.html", groups: ["channel"])
  end

  def toggle_favorite(user_id, channel_id) do
    {cc, user} = get_subscription_and_user(user_id, channel_id)

    cc_type =
      if cc.type == room_type(:starred) do
        cc.channel.type # change it back
      else
        room_type(:starred) # star it
      end

    Subscription.update!(cc, %{type: cc_type})

    chatd = ChatDat.new user, cc.channel, []

    messages_html = render_messages_header chatd

    side_nav_html =
      "rooms_list.html"
      |> UccChatWeb.SideNavView.render(chatd: chatd)
      |> Helpers.safe_to_string

    {:ok, %{messages_html: messages_html, side_nav_html: side_nav_html}}
  end

  defp get_subscription_and_user(user_id, channel_id) do
    cc = Subscription.get_by_channel_id_and_user_id(channel_id, user_id,
      preload: [:channel])
    user = Repo.one!(from u in User, where: u.id == ^user_id,
      preload: [:account])
   {cc, user}
  end

  def render_messages_header(user_id, channel_id) do
    channel = Channel.get! channel_id

    user_id
    |> Helpers.get_user!
    |> ChatDat.new(channel, [])
    |> render_messages_header
  end

  def render_messages_header(chatd) do
    "messages_header.html"
    |> UccChatWeb.MasterView.render(chatd: chatd)
    |> Helpers.safe_to_string
  end

  def add_direct(%{} = friend, user_id, channel_id) do
    user_orig = Accounts.get_user user_id, preload: [:account, :roles, user_roles: [:role]]

    name = user_orig.username <> "__" <> friend.username
    # Logger.warn "name: #{inspect name}"
    channel =
      case Channel.get_by(name: name) do
        %{} = channel -> channel
        _  -> do_add_direct(name, user_orig, friend, channel_id)
      end

    # user = Repo.one!(from u in User, where: u.id == ^user_id, preload: [:account, :roles])
    user =
      user_id
      |> Accounts.get_user(preload: [:account, :roles, user_roles: [:role]])
      |> Accounts.update_user!(%{open_id: channel.id})

    # TODO: I bet this is where we are not closing the existing subscription!
    #       We need to be doing the operation above along with closing any
    #       open subs.

    chatd = ChatDat.new user, channel, []

    messages_html =
      "messages_header.html"
      |> UccChatWeb.MasterView.render(chatd: chatd)
      |> Helpers.safe_to_string

    side_nav_html =
      "rooms_list.html"
      |> UccChatWeb.SideNavView.render(chatd: chatd)
      |> Helpers.safe_to_string

    {:ok, %{
      messages_html: messages_html,
      side_nav_html: side_nav_html,
      display_name: friend.username,
      channel_id: channel.id,
      room: channel.name,
      room_route: chatd.room_route
    }}
  end

  def add_direct(friend_id, user_id, channel_id) do
    friend_id
    |> Accounts.get_user(preload: [:account, :roles, user_role: [:role]])
    |> add_direct(user_id, channel_id)
  end

  defp do_add_direct(name, user_orig, friend, _channel_id) do
    # create the channel
    {:ok, channel} = insert_channel(%{user_id: user_orig.id, name: name,
      type: room_type(:direct)})

    # Create the cc's, and the directs one for each user
    user_ids = %{
      user_orig.id => friend.id,
      friend.id => user_orig.id
    }

    for user <- [user_orig, friend] do
      Subscription.create!(%{
        channel_id: channel.id,
        user_id: user.id,
        type: room_type(:direct)
      })
      Direct.create!(%{
        friend_id: user_ids[user.id],
        user_id: user.id,
        channel_id: channel.id
      })
    end

    UcxUccWeb.Endpoint.broadcast! CC.chan_user() <> to_string(friend.id),
      "direct:new", %{room: channel.name}
    channel
  end

  ###################
  # channel commands

  def channel_command(socket, :unhide, name, user_id, _channel_id) do
    channel_id = (Channel.get_by(name: name) || %{}) |> Map.get(:id)

    case Subscription.get_by(channel_id: channel_id, user_id: user_id) do
      nil ->
        {:error, "You are not subscribed to that room"}
      subs ->
        case Subscription.update(subs, %{hidden: false}) do
          {:ok, _} ->
            Phoenix.Channel.broadcast socket, "user:action",
              %{action: "unhide", user_id: user_id, channel_id: channel_id}
            {:ok, ""}
          {:error, _} ->
            {:error, ~g"Could not unhide that room"}
        end
    end
  end

  def channel_command(socket, :hide, name, user_id, _channel_id) do
    channel_id = (Channel.get_by(name: name) || %{}) |> Map.get(:id)

    case Subscription.get_by(channel_id: channel_id, user_id: user_id) do
      nil ->
        {:error, ~g"You are not subscribed to that room"}
      subs ->
        case Subscription.update(subs, %{hidden: true}) do
          {:ok, _} ->
            Phoenix.Channel.broadcast socket, "user:action",
              %{action: "hide", user_id: user_id}
            {:ok, ""}
          {:error, _} ->
            {:error, ~g"Could not hide that room"}
        end
    end
  end

  def channel_command(socket, :create, name, user_id, channel_id) do
    Logger.debug fn -> "name: #{inspect name}" end
    if is_map(name) do
      Helpers.response_message(channel_id, ~g"The channel " <> "`##{name}`" <>
        ~g" already exists.")
    else
      case insert_channel(%{name: name, user_id: user_id}) do
        {:ok, channel} ->
          channel_command(socket, :join, channel, user_id, channel_id)

          {:ok, ~g"Channel created successfully"}
        {:error, _} ->
          {:error, ~g"There was a problem creating " <> "`##{name}`"
            <> ~g" channel."}
      end
    end
  end

  def channel_command(socket, :leave, name, user_id, _) when is_binary(name) do
    Logger.debug fn -> "name: #{inspect name}" end
    case Channel.get_by(name: name) do
      nil ->
        {:error, ~g"The channels does not exist"}
      channel ->
        channel_command(socket, :leave, channel, user_id, channel.id)
    end
  end

  @channel_commands ~w(join leave open archive unarchive)a ++
    ~w(invite_all_to invite_all_from)a

  def channel_command(socket, command, name, user_id, channel_id)
    when command in @channel_commands and is_binary(name) do
    case Channel.get_by(name: name) do
      nil ->
        {:error, ~g"The channel " <> "`##{name}`" <> ~g" does not exists"}
      channel ->
        channel_command(socket, command, channel, user_id, channel_id)
    end
  end

  def channel_command(_socket, :join, %ChannelSchema{} = channel, user_id,
    _channel_id) do

    case add_user_to_channel(channel, user_id) do
      {:ok, _subs} ->
        {:ok, ~g"You have joined the " <> "`#{channel.name}`" <> ~g" channel."}
      {:error, _} ->
        {:error, ~g"Problem joining " <> "`#{channel.name}`" <> ~g" channel."}
    end
  end

  def channel_command(_socket, :leave, %ChannelSchema{} = channel, user_id,
    _channel_id) do
    # Logger.error ".... channel.name: #{inspect channel.name}, user_id: #{inspect user_id}, channel.id: #{inspect channel.id}"
    case WebChannel.leave(channel, user_id) do
      {:error, _} ->
        {:error, ~g"Your not subscribed to the " <> "`#{channel.name}`" <>
          ~g" channel."}
      _subs ->
        {:ok, ~g"You have left to the " <> "`#{channel.name}`" <>
          ~g" channel."}
    end
  end

  def channel_command(socket, :open, %ChannelSchema{name: name} = _channel,
    _user_id, _channel_id) do
    # send open channel to the user
    # old_room = Helpers.get!(Channel, socket.assigns.channel_id) |> Map.get(:name)
    # Logger.warn "old_room: #{inspect old_room}, channel: #{inspect channel}"
    # open_room(socket.assigns[:user_id], old_room, name, name)
    # Helpers.response_message(channel_id, "That command is not yet supported")
    Phoenix.Channel.push socket, "room:open", %{room: name}
    {:ok, %{}}
  end

  def channel_command(_socket, :archive, %ChannelSchema{archived: true} =
    channel, _user_id, channel_id) do
    Helpers.response_message(channel_id, "Channel with name " <>
      "`#{channel.name}` is already archived.")
  end

  def channel_command(socket, :archive, %ChannelSchema{id: id} = channel,
    user_id, _channel_id) do
    user = Helpers.get_user! user_id

    channel
    |> Channel.changeset(user, %{archived: true})
    |> Repo.update
    |> case do
      {:ok, _} ->
        # Logger.warn "archiving... #{id}, channel_id: #{inspect channel_id}, channel_name: #{channel.name}"
        Subscription.update_all_hidden(id, true)

        notify_action(socket, :archive, channel, user)
        # notify_user_action2(socket, user, user_id, id, &format_binary_msg(&1, &2, "archived"))
        # Phoenix.Channel.broadcast! socket, "room:state_change", %{change: "archive"}
        {:ok, ~g"Channel with name " <> "`#{channel.name}`" <>
          ~g" has been archived successfully."}
      {:error, cs} ->
        Logger.warn "error archiving channel #{inspect cs.errors}"
        {:error, ~g"Channel with name " <> "`#{channel.name}`" <>
          ~g" was not archived."}
    end
  end

  def channel_command(_socket, :unarchive, %ChannelSchema{archived: false} =
    channel, _user_id, _channel_id) do
    {:error, ~g"Channel with name " <> "`#{channel.name}`" <>
      ~g" is not archived."}
  end

  def channel_command(socket, :unarchive, %ChannelSchema{id: id} = channel,
    user_id, _channel_id) do
    user = Helpers.get_user! user_id

    channel
    |> Channel.changeset(user, %{archived: false})
    |> Repo.update
    |> case do
      {:ok, _} ->
        # Logger.warn "unarchiving... #{id}"
        Subscription.update_all_hidden(id, false)

        notify_action(socket, :unarchive, channel, user)
        {:ok, ~g"Channel with name " <> "`#{channel.name}`" <>
          ~g" has been unarchived successfully."}
      {:error, cs} ->
        Logger.warn "error unarchiving channel #{inspect cs.errors}"
        {:erorr, ~g"Channel with name " <> "`#{channel.name}`" <>
          ~g" was not unarchived."}
    end
  end

  def channel_command(_socket, :invite_all_to, %ChannelSchema{} = channel,
    _user_id, channel_id) do
    to_channel = Channel.get!(channel.id).id
    from_channel = channel_id

    from_channel
    |> Subscription.get_all_for_channel
    |> preload([:user])
    |> Repo.all
    |> Enum.each(fn subs ->
      # TODO: check for errors here
      invite_user(subs.user.id, to_channel)
    end)

    {:ok, "The users have been added."}
  end

  def channel_command(_socket, :invite_all_from, %ChannelSchema{} = channel,
    _user_id, channel_id) do
    from_channel = Channel.get!(channel.id).id
    to_channel = channel_id

    from_channel
    |> Subscription.get_all_for_channel
    |> preload([:user])
    |> Repo.all
    |> Enum.each(fn subs ->
      # TODO: check for errors here
      invite_user(subs.user.id, to_channel)
    end)

    {:ok, ~g"The users have been added."}
  end

  ##################
  # user commands

  @user_commands ~w(invite kick mute unmute block_user unblock_user)a

  def user_command(socket, command, name, user_id, channel_id)
    when command in @user_commands and is_binary(name) do
    case Helpers.get_user_by_name(name) do
      nil ->
        {:error, ~g"The user " <> "`@#{name}`" <> ~g" does not exists"}
      user ->
        user_command(socket, command, user, user_id, channel_id)
    end
  end

  def user_command(_socket, :invite, %User{} = user, user_id, channel_id) do
    case invite_user(user, channel_id, user_id) do
      {:ok, _subs} ->
        {:ok, ~g"User added"}
      {:error, _} ->
        {:error, ~g"Problem inviting " <> "`#{user.username}`" <>
          ~g" to this channel."}
    end
  end

  def user_command(socket, :kick, %User{} = user, user_id, channel_id) do
    channel_id
    |> kick_user(user, socket)
    |> case do
      nil ->
        {:error, ~g"User " <> "`#{user.username}`" <>
          ~g" is not subscribed to this channel."}
      _subs ->
        notify_user_action2(socket, user, user_id, channel_id,
            &format_binary_msg(&1, &2, "removed"))
        {:ok, ~g"User removed"}
    end
  end

    # field :hide_user_join, :boolean, default: false
    # field :hide_user_leave, :boolean, default: false
    # field :hide_user_removed, :boolean, default: false
    # field :hide_user_added, :boolean, default: false
  def user_command(socket, :block_user, %User{} = user, user_id, channel_id) do
    case block_user(user, user_id, channel_id) do
      {:ok, msg} ->
        # unless Settings.hide_user_muted() do
        #   notify_user_action2 socket, user, user_id, channel_id,
        #   &format_binary_msg(&1, &2, "muted")
        # end
        Phoenix.Channel.broadcast socket, "room:state_change",
          %{change: "block"}
        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "block", user_id: user.id}
        # Logger.warn "mute #{user.id} by #{user_id}...."
        {:ok, msg}
      error ->
        # Logger.error "user_command error #{inspect error}"
        error
    end
  end

  def user_command(socket, :unblock_user, %User{} = user, user_id,
    channel_id) do
    case unblock_user(user, user_id, channel_id) do
      {:ok, msg} ->
        # unless Settings.hide_user_muted() do
        #   notify_user_action2 socket, user, user_id, channel_id,
        #  &format_binary_msg(&1, &2, "muted")
        # end
        Phoenix.Channel.broadcast! socket, "room:state_change",
          %{change: "unblock"}
        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "block", user_id: user.id}
        # Logger.warn "mute #{user.id} by #{user_id}...."
        {:ok, msg}
      error ->
        # Logger.error "user_command error #{inspect error}"
        error
    end
  end

  def user_command(socket, :mute, %User{} = user, user_id, channel_id) do
    case mute_user(user, user_id, channel_id) do
      {:ok, msg} ->
        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "mute", user_id: user.id}
        {:ok, msg}
      error ->
        error
    end
  end

  def user_command(socket, :unmute, %User{} = user, user_id, channel_id) do
    case unmute_user(user, user_id, channel_id) do
      {:ok, msg} ->
        unless UccSettings.hide_user_muted() do
          notify_user_action2 socket, user, user_id, channel_id,
            &format_binary_msg(&1, &2, "unmuted")
        end

        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "mute", user_id: user.id}
        {:ok, msg}
      error ->
        error
    end
  end

  def user_command(socket, action, %User{} = user, user_id, channel_id)
    when action in [:set_owner, :unset_owner] do
    string =
      if action == :set_owner do
        "was set owner"
      else
        "is no longer owner"
      end

    case apply(__MODULE__, action, [user, user_id, channel_id]) do
      {:ok, msg} ->
        notify_user_action2 socket, user, user_id, channel_id,
          &format_binary_msg(&1, &2, string)

        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "owner", user_id: user.id}

        {:ok, msg}
      error ->
        Logger.error "user_command error #{inspect error}"
        error
    end
  end

  def user_command(socket, action, %User{} = user, user_id, channel_id)
    when action in [:set_moderator, :unset_moderator] do

    string =
      if action == :set_moderator do
        ~g"was set moderator"
      else
        ~g"is no longer moderator"
      end

    case apply(__MODULE__, action, [user, user_id, channel_id]) do
      {:ok, msg} ->
        notify_user_action2 socket, user, user_id, channel_id, &format_binary_msg(&1, &2, string)
        Phoenix.Channel.broadcast socket, "user:action", %{action: "moderator", user_id: user.id}
        # Logger.debug "#{inspect action} #{user.id} by #{user_id}...."
        {:ok, msg}
      error ->
        Logger.error "user_command error #{inspect error}"
        error
    end
  end

  def user_command(socket, :remove_user, %User{} = user, user_id, channel_id) do
    case apply(__MODULE__, :remove_user, [user, user_id, channel_id]) do
      {:ok, msg} ->
        notify_user_action2 socket, user, user_id, channel_id,
          &format_binary_msg(&1, &2, "removed by")
        Phoenix.Channel.broadcast socket, "user:action",
          %{action: "removed", user_id: user.id}
        # Logger.debug "#{inspect :remove_user} #{user.id} by #{user_id}...."
        {:ok, msg}
      error ->
        Logger.error "user_command error #{inspect error}"
        error
    end
  end

  def user_command(_socket, action, %User{}, _user_id, _channel_id) do
    raise "user command unknown action #{inspect action}"
  end

  def format_binary_msg(n1, n2, operation) do
    ~g"User" <> " <em class='username'>#{n1}</em> " <>
      Gettext.gettext(UcxUccWeb.Gettext, operation) <> " " <> ~g"by" <>
      " <em class='username'>#{n2}</em>."
  end
  # def notify_action(socket, action, resource, owner_id, channel_id)

  def notify_user_action2(socket, user, user_id, _channel_id, fun) do
    owner = Helpers.get_user user_id, preload: []
    _body = fun.(user.username, owner.username)
    # broadcast_message2(socket, body, user_id, channel_id, system: true)
    socket
  end

  def block_user(%{id: _id}, _user_id, channel_id) do
    channel_id
    |> Channel.get!
    |> Channel.blocked_changeset(true)
    |> Repo.update
    |> case do
      {:error, _cs} ->
        {:error, ~g"Could not block user"}
      _ ->
        {:ok, ~g"blocked"}
    end
  end

  def unblock_user(_user, _user_id, channel_id) do
    channel_id
    |> Channel.get!
    |> Channel.blocked_changeset(false)
    |> Repo.update
    |> case do
      {:error, _cs} ->
        {:error, ~g"Could not unblock user"}
      _ ->
        {:ok, ~g"unblocked"}
    end
  end

  def mute_user(%{id: id} = user, user_id, channel_id) do
    if Permissions.has_permission?(Helpers.get_user!(user_id), "mute-user", channel_id) do
      case Mute.create(%{user_id: id, channel_id: channel_id}) do
        {:error, _cs} ->
          message = ~g"User" <> " `@" <> user.username <> "` " <> ~g"already muted."
          {:error, message}
        _mute ->
          current_user = Accounts.get_user user_id, preload: [:account, :roles, user_role: [:role]]
          unless UccSettings.hide_user_muted() do
            message = ~g(User ) <> user.username <> ~g( muted by ) <> current_user.username
            WebMessage.broadcast_system_message(channel_id, current_user.id, message)
          end
          {:ok, ~g"muted"}
      end
    else
      {:error, :no_permission}
    end
  end

  def unmute_user(%{id: id} = user, user_id, channel_id) do
    if Permissions.has_permission?(Helpers.get_user!(user_id), "mute-user",
      channel_id) do
      case Mute.get_by user_id: id, channel_id: channel_id do
        nil ->
          {:error, ~g"User" <> " `@" <> user.username <> "` " <>
            ~g"is not muted."}
        mute ->
          Repo.delete mute
          current_user = Accounts.get_user user_id, preload: [:account, :roles, user_role: [:role]]
          unless UccSettings.hide_user_muted() do
            message = ~g(User ) <> user.username <> ~g( unmuted by ) <> current_user.username
            WebMessage.broadcast_system_message(channel_id, current_user.id, message)
          end
          {:ok, ~g"unmuted"}
      end
    else
      {:error, :no_permission}
    end
  end

  def set_owner(%{id: id} = _user, _user_id, channel_id) do
    %UserRole{}
    |> UserRole.changeset(%{user_id: id, role: "owner", scope: channel_id})
    |> Repo.insert
    |> case do
      {:error, _cs} ->
        {:error, ~g"Could not add role to user."}
      user_role ->
        {:ok, user_role}
    end
  end

  def unset_owner(%{id: id}, _user_id, channel_id) do
    owners = Repo.all(from r in UserRole, where: r.role == "owner" and
      r.scope == ^channel_id)

    if length(owners) > 1 do
      owners
      |> Enum.find(&(&1.user_id == id))
      |> remove_role
    else
      {:error, ~g"This is the last owner. Please set a new owner before " <>
        "removing this one."}
    end
  end

  def set_moderator(%{id: id}, _user_id, channel_id) do
    %UserRole{}
    |> UserRole.changeset(%{user_id: id, role: "moderator", scope: channel_id})
    |> Repo.insert
    |> case do
      {:error, _cs} ->
        {:error, ~g"Could not add user as moderator."}
      user_role ->
        {:ok, user_role}
    end
  end

  def unset_moderator(%{id: id}, _user_id, channel_id) do
    Repo.one(from r in UserRole, where: r.user_id == ^id and
      r.role == "moderator" and  r.scope == ^channel_id)
    |> remove_role
  end

  def remove_user(%{id: _id}, _user_id, _channel_id) do
    raise "not implemented"
    # channel = Channel.get channel_id
    # owners = Repo.all(from r in UserRole, where: r.user_id != ^id and
    #   r.role == "owner" and  r.scope == ^channel_id)
    # if length(owners) > 0 do
    #   case WebChannel.remove_user(channel, id) do
    #     nil ->
    #       {:error, ~g"User is not a member of this room."}
    #     _ ->
    #       {:ok, ""}
    #   end
    # else
    #   {:error, ~g"You are the last owner. Please set a new owner before " <>
    #     "leaving this room."}
    # end
  end

  def invite_user(user, channel_id, current_user_id \\ [], opts \\ [])
  def invite_user(%User{} = user, channel_id, current_user_id, opts)
    when is_binary(current_user_id) do
    invite_user(user.id, channel_id, opts)
  end

  def invite_user(user_id, channel_id, opts, _) when is_list(opts) do
    channel_id
    |> Channel.get!
    |> WebChannel.add_user(user_id)
  end

  def kick_user(_channel_id, _user, _socket) do
    raise "not implemented"
    # channel_id
    # |> Channel.get!
    # |> WebChannel.remove_user(user.id)
  end

  def remove_role(nil) do
    {:error, ~g"Role not found"}
  end

  def remove_role(user_role) do
    Repo.delete! user_role
    {:ok, :success}
  end

  #################
  # Helpers

  #def get_templ(:starred), do: "starred_rooms.html"
  def get_templ(:starred), do: "stared_rooms.html"
  def get_templ(:direct), do: "direct_messages.html"
  def get_templ(_), do: "channels.html"

  def get_icon(%{type: type}), do: get_icon(type)
  def get_icon(0), do: "icon-hash"
  def get_icon(1), do: "icon-lock"
  def get_icon(2), do: "icon-at"
  def get_icon(3), do: "icon-at"
  # def get_icon(:public), do: "icon-hash"
  # def get_icon(:private), do: "icon-hash"
  # def get_icon(:starred), do: "icon-hash"
  # def get_icon(:direct), do: "icon-at"

  # def broadcast_message(body, room, user_id, channel_id, opts \\ []) do
  #   {message, html} = MessageService.create_and_render(body, user_id, channel_id, opts)
  #   MessageService.broadcast_message(message.id, room, user_id, html)
  # end

  # def broadcast_message2(socket, body, user_id, channel_id, opts \\ []) do
  #   {message, html} =
  #     MessageService.create_and_render(body, user_id, channel_id, opts)
  #   MessageService.broadcast_message(socket, message.id, user_id, html)
  # end

  # def remove_user_from_channel(channel, user_id) do
  #   case Subscription.get_by channel_id: channel.id, user_id: user_id do
  #     nil ->
  #       nil
  #     subs ->
  #       user = Accounts.get_user user_id
  #       Repo.delete! subs
  #       UserChannel.leave_room(user_id, channel.name)
  #       UccPubSub.broadcast "user:" <> user_id, "delete:subscription",
  #         %{channel_id: channel.id}
  #       notity_user_leave(channel.id, user)
  #       {:ok, ~g"removed"}
  #   end
  # end

  def add_user_to_channel(channel, user_id, opts \\ []) do
    case join_channel(channel, user_id, opts) do
      {:ok, _subs} ->
        {:ok, ~g"added"}
      result -> result
    end
  end

  def user_muted?(user_id, channel_id) do
    Logger.warn "deprecated. Use Channel.user_muted?/2 instead"
    !! Mute.get_by(user_id: user_id, channel_id: channel_id)
  end

  def room_icon(channel_id) do
    channel = Channel.get channel_id
    get_icon channel.type
  end

  def notity_user_join(_channel_id, _user) do
    raise "not implemented"
    # unless Settings.hide_user_join do
    #   MessageService.broadcast_system_message channel_id, user.id,
    #     user.username <> ~g( has joined the channel.)
    # end
  end

  def notify_user_removed(_channel_id, _user) do
    raise "not implemented"
    # unless Settings.hide_user_removed do
    #   MessageService.broadcast_system_message channel_id, user.id,
    #     user.username <> ~g( has been removed from the channel.)
    # end
  end

  def notity_user_leave(_channel_id, _user) do
    raise "not implemented"
    # unless UccSettings.hide_user_leave() do
    #   MessageService.broadcast_system_message channel_id, user.id,
    #     user.username <> ~g( has left the channel.)
    # end
  end
  # def get_route(@starred_room, name), do: "/direct/" <> name
  # def get_route(@direct_message, name), do: "/direct/" <> name
  # def get_route(_, name), do: "/channel/" <> name
end
