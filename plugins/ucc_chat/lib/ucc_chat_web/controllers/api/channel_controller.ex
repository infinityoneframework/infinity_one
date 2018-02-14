defmodule UccChatWeb.API.ChannelController do
  use UccChatWeb, :controller

  plug :put_layout, false

  alias UccChat.Channel

  require Logger

  def show(conn, params) do
    Logger.warn "conn: " <> inspect(conn)
    case Channel.get_by name: params["name"], preload: [:owner, :users, :messages] do
      nil ->
        render conn, error: [message: "channel not found"]

      channel ->
        usernames = Enum.map(channel.users, & &1.username)
        msgs = length channel.messages
        owner = %{username: channel.owner.username, id: channel.owner.id}

        channel =
          ~w(subscriptions users attachments messages notifications starred_messages __meta__)a
          |> Enum.reduce(Map.from_struct(channel), fn key, acc ->
            Map.delete(acc, key)
          end)
          |> Map.put(:usernames, usernames)
          |> Map.put(:msgs, msgs)
          |> Map.put(:owner, owner)

        render conn, success: [channel: channel]
    end
  end
end
