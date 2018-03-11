defmodule OneChatWeb.RoomChannel.MessageInput.Users do
  use OneChatWeb.RoomChannel.Constants

  import InfinityOneWeb.Utils
  import Rebel.{Core, Query}, warn: false
  import InfinityOneWeb.Gettext
  import InfinityOne.Permissions, only: [has_permission?: 3]

  alias InfinityOne.Accounts
  alias OneChatWeb.MessageView
  alias OneChat.{PresenceAgent, Message}

  require OneChatWeb.RoomChannel.MessageInput
  require Logger

  @extra_users_hash %{
    "all" => %{
      system: true,
      username: "all",
      name: ~g"Notify all in this room",
      id: "all"
    },
    "here" => %{
      system: true,
      username: "here",
      name: ~g"Notify active users in this room",
      id: "here"
    },
    "all!" => %{
      system: true,
      username: "all!",
      name: ~g"Notify all online users",
      id: "all!"
    }
  }

  @extra_users        Map.values(@extra_users_hash)
  @extra_users_keys   Map.keys(@extra_users_hash)
  @extra_users_count  length(@extra_users_keys)

  def extra_users, do: @extra_users
  def extra_users_keys, do: @extra_users_keys
  def extra_users_count, do: @extra_users_count

  def handle_in("@" <> pattern, context) do
    handle_in pattern, context
  end
  def handle_in(pattern, context) do
    user = Accounts.get_user context.user_id, default_preload: true
    # Logger.warn "Users handle_in pattern: #{inspect pattern}"
    "%" <> pattern <> "%"
    |> get_users(context.channel_id, context.user_id, pattern, user)
    |> render_users(context)
  end

  def handle_select(buffer, selected, context) do
    if selected != "" do
      buffer = Poison.encode!(buffer <> " ")
      context.client.async_js context.socket, """
        var te = document.querySelector('#{@message_box}');
        te.value = #{buffer};
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

  defp get_users(pattern, channel_id, user_id, original_pattern, user) do
    channel_id
    |> get_users_by_pattern(user_id, pattern)
    |> add_extra_users(original_pattern, user, channel_id)
  end

  defp add_extra_users([], pattern, user, channel_id) do
    @extra_users
    |> Enum.filter(& &1.id =~ pattern)
    |> check_extras_permissions(user, channel_id)
  end

  defp add_extra_users(users, "", user, channel_id) do
    extra_users = check_extras_permissions(@extra_users, user, channel_id)
    extra_users_count = length extra_users

    Enum.take(users, 8 - extra_users_count) ++ extra_users
  end

  defp add_extra_users(users, pattern, user, channel_id) do
    extra_users =
      @extra_users
      |> Enum.filter(& &1.id =~ pattern)
      |> check_extras_permissions(user, channel_id)
    extra_users_count = length extra_users
    Enum.take(users, 8 - extra_users_count) ++ extra_users
  end

  defp check_extras_permissions(list, user, channel_id) do
    list
    |> Enum.reduce([], fn
      %{id: "all"} = item, acc ->
        if has_permission? user, "mention-all", channel_id do
          [item | acc]
        else
          acc
        end
      %{id: "all!"} = item, acc ->
        if has_permission? user, "mention-all!", channel_id do
          [item | acc]
        else
          acc
        end
      %{id: "here"} = item, acc ->
        if has_permission? user, "mention-here", channel_id do
          [item | acc]
        else
          acc
        end
      _, acc ->
        acc
    end)
    |> Enum.reverse
  end

  defp get_users_by_pattern(channel_id, user_id, pattern) do
    channel_users = get_default_users(channel_id, user_id, pattern)
    case length channel_users do
      max when max >= 8 -> channel_users
      size ->
        exclude = Enum.map(channel_users, &(&1[:id]))
        channel_users ++ get_all_users(pattern, exclude, 8 - size)
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
