defmodule UccChatWeb.RoomChannel.MessageInput.Users do
  use UccChatWeb.RoomChannel.Constants

  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import UcxUccWeb.Gettext

  alias UcxUcc.Accounts
  alias UccChatWeb.MessageView
  alias UccChat.{PresenceAgent, Message}

  require UccChatWeb.RoomChannel.MessageInput
  require Logger

  def handle_in("@" <> pattern, context) do
    handle_in pattern, context
  end
  def handle_in(pattern, context) do
    # Logger.warn "Users handle_in pattern: #{inspect pattern}"
    "%" <> pattern <> "%"
    |> get_users(context.channel_id, context.user_id)
    |> render_users(context)
  end

  def handle_select(buffer, selected, context) do
    if selected != "" do
      context.client.send_js context.socket, """
        var te = document.querySelector('#{@message_box}');
        te.value = '#{buffer} ';
        te.focus();
        """
    end
  end

  defp render_users([], context) do
    context.client.close_popup context.socket
    :close
  end
  defp render_users(users, context) do
    # Logger.warn "users: #{inspect users}"
    MessageView
    |> render_to_string("popup.html", chatd: %{
      app: "Users",
      open: true,
      data: users,
      title: ~g"People",
      templ: "popup_user.html"
    })
    |> context.client.render_popup_results(context.socket)
  end

  defp get_users(pattern, channel_id, user_id) do
    channel_id
    |> get_users_by_pattern(user_id, pattern)
    |> add_extra_users
  end

  defp add_extra_users([]), do: []
  defp add_extra_users(users) do
    users ++ [
      %{
        system: true,
        username: "all",
        name: ~g"Notify all in this room",
        id: "all"
      },
      %{
        system: true,
        username: "here",
        name: ~g"Notify active users in this room",
        id: "here"
      }
    ]
  end

  defp get_users_by_pattern(channel_id, user_id, pattern) do
    channel_users = get_default_users(channel_id, user_id, pattern)
    case length channel_users do
      max when max >= 5 -> channel_users
      size ->
        exclude = Enum.map(channel_users, &(&1[:id]))
        channel_users ++ get_all_users(pattern, exclude, 5 - size)
    end
  end

  def get_default_users(channel_id, user_id, pattern \\ "%") do
    channel_id
    |> Message.get_user_ids(user_id)
    |> Accounts.list_users_by_pattern(pattern)
    |> Enum.map(fn user ->
      %{username: user.username, id: user.id,
        status: PresenceAgent.get(user.id)}
    end)
  end

  def get_all_users(pattern, exclude, count) do
    pattern
    |> Accounts.list_all_users_by_pattern(exclude, count)
    |> Enum.map(fn user ->
      %{id: user.id, username: user.username,
        status: PresenceAgent.get(user.id)}
    end)
  end

end
