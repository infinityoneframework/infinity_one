defmodule UccChat.ChatDat do
  alias UccChat.{Channel}
  alias UcxUcc.{Repo, Hooks, Accounts, Accounts.User}
  alias UccChat.Schema.Channel, as: ChannelSchema
  alias UccChatWeb.RoomChannel.Message

  require Logger

  defstruct user: nil, room_types: [], settings: %{}, rooms: [],
            channel: nil, messages: nil, room_map: %{}, active_room: %{},
            status: "offline", room_route: "channels", messages_info: %{},
            previews: [], search_empty: false

  def new(user, channel, messages \\ [])
  def new(%User{roles: %Ecto.Association.NotLoaded{}} = user,
    %ChannelSchema{} = channel, messages) do
    user
    |> Repo.preload([:roles, user_roles: :role])
    |> new(channel, messages)
  end

  def new(%User{} = user, %ChannelSchema{} = channel, messages) do
    user = Hooks.preload_user user, []
    %{room_types: room_types, rooms: rooms, room_map: room_map, active_room: ar} =
      UccChat.ChannelService.get_side_nav(user, channel.id)

    previews = Message.message_previews(user.id, messages)
    status = UccChat.PresenceAgent.get user.id

    %__MODULE__{
      status: status,
      user: user,
      room_types: room_types,
      rooms: rooms,
      room_map: room_map,
      channel: channel,
      messages: messages,
      active_room: ar,
      room_route: Channel.room_route(channel),
      previews: previews
    }
  end

  def new(%User{} = user, nil, _), do: new(user)

  def new(%User{} = user, channel_id, messages) do
    channel = Channel.get(channel_id)
    new(user, channel, messages)
  end

  def new(user) do
    user = Hooks.preload_user user, []
    %{room_types: room_types, rooms: rooms, room_map: room_map,
      active_room: _ar} =
        UccChat.ChannelService.get_side_nav(user, nil)

    status = UccChat.PresenceAgent.get user.id
    %__MODULE__{
      status: status,
      user: user,
      room_types: room_types,
      rooms: rooms,
      room_map: room_map,
      channel: nil,
      messages: [],
      active_room: 0,
      room_route: "home"
    }
  end

  def new_search(user, match, channel_id, opts \\ [])
  def new_search(%{} = user, match, channel_id, opts) do
    %{room_types: room_types, rooms: rooms, room_map: room_map,
      active_room: _ar, search_empty: empty} =
        UccChat.ChannelService.get_side_nav_search(user, match, channel_id, opts)

    status = UccChat.PresenceAgent.get user.id
    %__MODULE__{
      status: status,
      user: user,
      room_types: room_types,
      rooms: rooms,
      room_map: room_map,
      channel: nil,
      messages: [],
      active_room: 0,
      room_route: "home",
      search_empty: empty,
    }
  end

  def new_search(user_id, match, channel_id, opts) do
    user_id
    |> Accounts.get_user
    |> new_search(match, channel_id, opts)
  end

  def get_messages_info(chatd) do
    get_messages_info(chatd, chatd.user)
  end

  def get_messages_info(chatd, user) do
    case chatd.channel do
      %ChannelSchema{id: id} ->
        value = Message.get_messages_info(chatd.messages, id, user)
        set(chatd, :messages_info, value)
      _ ->
        chatd
    end
  end

  def set(chatd, field, value) do
    struct chatd, [{field, value}]
  end

  def favorite_room?(%__MODULE__{} = chatd, channel_id) do
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

  def get_channel_data(%__MODULE__{channel: %ChannelSchema{id: id},
    room_map: map}), do: map[id]

end
