defmodule OneChatWeb.API.MessageController do
  use OneChatWeb, :controller

  # plug :put_layout, false

  alias OneChat.Message
  alias InfinityOne.Accounts

  require Logger

  def show(conn, _params) do
    Logger.warn "conn: " <> inspect(conn)
    # case Channel.get_by name: params["name"], preload: [:owner, :users, :messages] do
    #   nil ->
    #     render conn, error: [message: "channel not found"]

    #   channel ->
    #     usernames = Enum.map(channel.users, & &1.username)
    #     msgs = length channel.messages
    #     owner = %{username: channel.owner.username, id: channel.owner.id}

    #     channel =
    #       ~w(subscriptions users attachments messages notifications starred_messages __meta__)a
    #       |> Enum.reduce(Map.from_struct(channel), fn key, acc ->
    #         Map.delete(acc, key)
    #       end)
    #       |> Map.put(:usernames, usernames)
    #       |> Map.put(:msgs, msgs)
    #       |> Map.put(:owner, owner)

    #     render conn, success: [channel: channel]
    # end
  end

  def create(conn, params) do
    Logger.warn "params: " <> inspect(params)
    Logger.warn "conn: " <> inspect(conn)

    # TODO: Need to validate this with a Coherence plug
    # _auth_token = conn.req_headers["x-auth-token"]
    user_id =
      case List.keyfind(conn.req_headers, "x-user-id", 0) do
        {_, val} -> val
        other -> other
      end
      |> IO.inspect(label: "user_id")

    case Accounts.get_user user_id, preload: [:roles, user_roles: [:role]] do
      nil ->
        render conn, error: [message: "invalid user!"]
      user ->
        "#" <> channel_name = params["channel"]
        body = params["text"]
        channel = OneChat.Channel.get_by(name: channel_name) |> IO.inspect(label: "channel")

        # need to create and broadcast this message
        case Message.create(%{body: body, user_id: user.id, channel_id: channel.id}) do
          {:ok, message} ->
            channel = %{id: message.channel_id, name: channel_name}
            user1 = %{id: user.id, username: user.username}

            message1 =
              ~w(__meta__ attachments channel reactions stars user_id channel_id edited_by edited_id)a
              |> Enum.reduce(Map.from_struct(message), fn key, acc ->
                Map.delete acc, key
              end)
              |> Map.put(:channel, channel)
              |> Map.put(:user, user1)

            render conn, success: [message: message1]

          {:error, changeset} ->
            error_string = OneChatWeb.SharedView.format_errors(changeset)
            render conn, error: [message: error_string]
        end
    end
  end
end
