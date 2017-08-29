defmodule UccChatWeb.RoomChannel.MessageInput.Users do
  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import UcxUccWeb.Gettext

  alias UcxUcc.Accounts
  alias UccChatWeb.MessageView
  alias UccChat.{PresenceAgent, Message}

  require UccChatWeb.RoomChannel.Constants, as: Const
  require Logger

  def new(mb_data, _key, info) do
    # Logger.warn "new mb_data: #{inspect mb_data}"
    "%"
    |> get_users(info.channel_id, info.user_id)
    |> render_users(mb_data, info.socket)

    Map.put mb_data, :app, Users
  end

  def handle_in(mb_data, _key, info) do
    # Logger.warn "Slash commands handle_in mb_data: #{inspect mb_data}"
    "%" <> mb_data.keys <> "%"
    |> get_users(info.channel_id, info.user_id)
    |> render_users(mb_data, info.socket)
  end

  def handle_select(mb_data, selected, info) do
    if selected != "" do
      exec_js info.socket, """
        var te = document.querySelector('#{Const.message_box}');
        te.value = '@#{selected}';
        te.focus();
        """ |> strip_nl
    end
    mb_data
  end

  defp render_users(nil, mb_data, _socket), do: mb_data
  defp render_users(users, mb_data, socket) do
    html = render_to_string MessageView,
      "popup.html",
      chatd: %{open: true, data: users, title: ~g"People", templ: "popup_user.html"}

    update socket, :html, set: html, on: ".message-popup-results"
    mb_data
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
