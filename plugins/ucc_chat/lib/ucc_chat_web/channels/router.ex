defmodule UccChatWeb.ChannelRouter do
  use ChannelRouter

  alias UccChatWeb.{
    TypingChannelController, SlashCommandChannelController,
    MessageChannelController,
    RoomChannelController, RoomSettingChannelController
  }
  # @module __MODULE__

  def match(:post, socket, ["typing"], params) do
    # module and action are build by the post macro
    apply(TypingChannelController, :create, [socket, params])
  end

  def match(:delete, socket, ["typing"], params) do
    apply(TypingChannelController, :delete, [socket, params])
  end

  def match(:put, socket, ["slashcommand", command], params) do
    params = Map.put(params, "command", command)
    # can? socket, :execute, params, fn ->
    apply(SlashCommandChannelController, :execute, [socket, params])
    # end
  end
  # get "/room/:room_id", RoomChannelController, :show
  # put "/room/favorite", RoomChannelController, :favorite

  def match(:delete, socket, ["attachment", id], params) do
    params = Map.put(params, "id", id)
    apply(MessageChannelController, :delete_attachment,
      [socket, params])
  end
  def match(:delete, socket, ["room", "has_unread"], params) do
    apply(RoomChannelController, :clear_has_unread, [socket, params])
  end
  def match(:put, socket, ["room", "has_unread"], params) do
    apply(RoomChannelController, :set_has_unread, [socket, params])
  end
  def match(:delete, socket, ["room", room], params) do
    params = Map.put(params, "room", room)
    apply(RoomChannelController, :delete, [socket, params])
  end
  def match(:get, socket, ["room", room_id], params) do
    params = Map.put(params, "room_id", room_id)
    apply(RoomChannelController, :show, [socket, params])
  end

  def match(:put, socket, ["room", "favorite"], params) do
    apply(RoomChannelController, :favorite, [socket, params])
  end

  def match(:put, socket, ["room", "hide", room], params) do
    params = Map.put(params, "room", room)
    apply(RoomChannelController, :hide, [socket, params])
  end

  def match(:put, socket, ["room", "leave", room], params) do
    params = Map.put(params, "room", room)
    apply(RoomChannelController, :leave, [socket, params])
  end

  def match(:put, socket, ["room", command, username], params) do
    params =
      [{"command", command}, {"username", username}]
      |> Enum.into(params)
    apply(RoomChannelController, :command, [socket, params])
  end

  # post "/direct/:username", DirectMessageChannelController, :create
  # post "/direct/:username", RoomChannelController, :create

  def match(:put, socket, ["direct", username], params) do
    params = Map.put(params, "username", username)
    apply(RoomChannelController, :create, [socket, params])
  end

  def match(:post, socket, ["messages"], params) do
    apply(MessageChannelController, :create, [socket, params])
  end
  def match(:get, socket, ["messages", "surrounding"], params) do
    apply(MessageChannelController, :surrounding, [socket, params])
  end
  # def match(:get, socket, ["messages", "last"], params) do
  #   apply(MessageChannelController, :last, [socket, params])
  # end
  def match(:get, socket, ["messages", "previous"], params) do
    apply(MessageChannelController, :previous, [socket, params])
  end
  def match(:get, socket, ["messages"], params) do
    apply(MessageChannelController, :index, [socket, params])
  end
  def match(:put, socket, ["messages", message_id], params) do
    params = Map.put(params, "id", message_id)
    apply(MessageChannelController, :update, [socket, params])
  end

  def match(:get, socket, ["room_settings", field_name], params) do
    params = Map.put(params, "field_name", field_name)
    apply(RoomSettingChannelController, :edit, [socket, params])
  end

  def match(:get, socket, ["room_settings", field_name, "cancel"], params) do
    params = Map.put(params, "field_name", field_name)
    apply(RoomSettingChannelController, :cancel, [socket, params])
  end

  def match(:put, socket, ["room_settings", field_name], params) do
    params = Map.put(params, "field_name", field_name)
    apply(RoomSettingChannelController, :update, [socket, params])
  end

end
