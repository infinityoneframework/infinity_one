defmodule OneChatWeb.FlexBar.Tab.MembersList do
  use OneChatWeb.FlexBar.Helpers

  alias OneChat.Channel
  alias OneChatWeb.FlexBarView
  alias OneChat.Accounts
  alias TabBar.Ftab
  alias TabBar.Tab
  alias OneWebrtcWeb.FlexBar.Tab.MembersList, as: WebrtcMembersList
  alias OneChatWeb.RoomChannel.Channel, as: WebChannel
  alias OneChatWeb.RebelChannel.Client

  require OneChat.ChatConstants, as: CC
  require Logger

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group im],
      "members-list",
      ~g"Members List",
      "icon-users",
      View,
      "users_list.html",
      40)
  end

  def args(socket, {user_id, _channel_id, _, _}, opts) do
    current_user = Helpers.get_user!(user_id)
    channel_id = socket.assigns.channel_id
    channel = Channel.get(channel_id, preload: [users: [:roles, user_roles: :role]])

    {user, user_mode} =
      case opts["username"] do
        nil ->
          {Helpers.get_user!(user_id), false}
        username ->
          {Helpers.get_user_by_name(username, preload: [:roles, user_roles: :role]), true}
      end

    users =
      channel
      |> Accounts.get_all_channel_online_users

    total_count = channel.users |> length

    user_info =
      channel
      |> user_info(user_mode: user_mode, view_mode: true)
      |> Map.put(:total_count, total_count)

    {[users: users, user: user, user_info: user_info,
     channel_id: channel_id, current_user: current_user], socket}
  end

  def user_args(socket, user_id, channel_id, username) do
    channel = Channel.get(channel_id, preload: [users: [:roles, user_roles: :role]])
    preload = InfinityOne.Hooks.user_preload [:roles, user_roles: :role]
    if user = Helpers.get_user_by_name(username, preload: preload) do
      {[
        user: user,
        user_info: user_info(channel, user_mode: true, view_mode: true),
        channel_id: channel_id,
        current_user: Helpers.get_user(user_id)
      ], socket}
    else
      nil
    end
  end

  # this is needed since we are overriding below
  def open(socket, {user_id, channel_id, tab, sender}, nil) do
    super(socket, {user_id, channel_id, tab, sender}, nil)
  end

  # TODO: Figure out how to have this detect this.
  def open(socket, {current_user_id, channel_id, tab, sender}, %{"view" => "video"} = args) do
    WebrtcMembersList.open(socket, {current_user_id, channel_id, tab, sender}, args)
  end

  def open(socket, {user_id, _channel_id, tab, sender}, %{"view" => "user"} = args) do
    username = args["username"]
    channel_id = socket.assigns.channel_id

    case user_args(socket, user_id, channel_id, username) do
      {args, socket} ->
        html =
          View
          |> Phoenix.View.render_to_string("user_card.html", args)
          |> String.replace(~s('), ~s(\\'))
          |> String.replace("\n", " ")

        selector = ".flex-tab-container .user-view"

        socket
        |> super({user_id, channel_id, tab, sender}, nil)
        |> async_js(~s/$('#{selector}').replaceWith('#{html}'); Rebel.set_event_handlers('#{selector}')/)
      _ ->
        socket
    end
  end

  def flex_show_all(socket, sender) do
    channel_id = exec_js!(socket, "ucxchat.channel_id")

    users =
      channel_id
      |> Channel.get!(preload: [:users])
      |> Accounts.get_channel_offline_users

    html =
      for user <- users do
        Phoenix.View.render_to_string FlexBarView, "users_list_item.html",
          user: user, channel_id: channel_id
      end
      |> Enum.join("")

    socket
    |> exec_update_fun(sender, "flex_show_online")
    |> insert(html, append: ".list-view ul.lines")
    |> update(:text, set: ~g(Show only online), on: this(sender))
    |> exec_update_showing_count
  end

  def flex_show_online(socket, sender) do
    socket
    |> exec_update_fun(sender, "flex_show_all")
    |> delete(".list-view ul.lines li.status-offline")
    |> update(:text, set: ~g(Show all), on: this(sender))
    |> exec_update_showing_count
    socket
  end

  defp exec_update_showing_count(socket) do
    broadcast_js(socket,
      "$('.showing-cnt').text($('.list-view ul.lines li').length)")
    socket
  end

  def flex_user_open(socket, sender) do
    user_id = socket.assigns[:user_id]
    channel_id = Rebel.get_assigns(socket, :channel_id)
    username = sender["dataset"]["username"]

    tab = TabBar.get_button "members-list"

    Ftab.open user_id, channel_id, "members-list", %{"username" => username,
      "view" => "user"}, fn :open, {_, args} ->
        apply tab.module, :open, [socket, {user_id, channel_id, tab, sender}, args]
      end
  end

  def view_all(%{assigns: assigns} = socket, _sender) do
    TabBar.close_view assigns.user_id, assigns.channel_id, "members-list"

    update(socket, :class, toggle: "animated-hidden",
      on: ".flex-tab-container .user-view")
  end

  # def mute_user(socket, %{} = sender) do
  #   mute_user socket, sender["dataset"]["id"]
  # end

  # def mute_user(socket, user_id) do
  #   current_user = Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
  #   user = Accounts.get_user user_id
  #   channel_id = socket.assigns.channel_id
  #   case WebChannel.mute_user channel_id, user, current_user do
  #     {:ok, _message} ->
  #       socket
  #       |> update_mute_unmute_button(channel_id, user, current_user)
  #       |> Client.toastr!(:success, ~g(User muted))
  #     {:error, message} ->
  #       Client.toastr! socket, :error, message
  #   end
  # end

  # def unmute_user(socket, %{} = sender) do
  #   unmute_user socket, sender["dataset"]["id"], socket.assigns.channel_id
  # end

  # def unmute_user(socket, user_id, channel_id) do
  #   current_user = Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
  #   user = Accounts.get_user user_id
  #   case WebChannel.unmute_user socket.assigns.channel_id, user, current_user do
  #     {:ok, _message} ->
  #       socket
  #       |> update_mute_unmute_button(channel_id, user, current_user)
  #       |> Client.toastr!(:success, ~g(User unmuted))
  #     {:error, message} ->
  #       Client.toastr! socket, :error, message
  #   end
  # end

  def set_mute(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.mute_user channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_mute_unmute_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g"User muted"
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  def unset_mute(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.unmute_user channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_mute_unmute_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g(User unmuted)
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  def set_owner(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.set_owner channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_set_remove_owner_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g"Set user as owner"
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  def unset_owner(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.unset_owner channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_set_remove_owner_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g(Removed user as owner)
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  def set_moderator(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.set_moderator channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_set_remove_moderator_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g(Set user as moderator)
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  def unset_moderator(socket, _sender) do
    username = select socket, data: "username", from: ".user-view[data-username]"
    # Logger.warn "username: #{inspect username}, sender: #{inspect sender}"
    user = InfinityOne.Accounts.get_by_user username: username
    channel_id = socket.assigns.channel_id
    current_user = InfinityOne.Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    case WebChannel.unset_moderator channel_id, user, current_user do
      {:ok, _} ->
        user = InfinityOne.Accounts.get_user(user.id, preload: [:roles, user_roles: :role])
        update_set_remove_moderator_button socket, channel_id, user, current_user
        Client.toastr socket, :success, ~g(Set user as moderator)
      {:error, message} ->
        Client.toastr socket, :error, message
    end
    socket
  end

  defp update_set_remove_owner_button(socket, channel_id, user, current_user) do
    # Logger.warn "assigns: #{inspect socket.assigns}"
    html =
      Phoenix.View.render_to_string OneChatWeb.FlexBarView,
        "user_card_owner_button.html", [
          channel_id: channel_id,
          user: user,
          current_user: current_user
        ]
    socket.endpoint.broadcast! CC.chan_room <> socket.assigns.room,
      "update:flex-button", %{username: user.username, html: html, button: "set-remove-owner"}
    socket
  end

  defp update_set_remove_moderator_button(socket, channel_id, user, current_user) do
    # Logger.warn "assigns: #{inspect socket.assigns}"
    html =
      Phoenix.View.render_to_string OneChatWeb.FlexBarView,
        "user_card_moderator_button.html", [
          channel_id: channel_id,
          user: user,
          current_user: current_user
        ]
    socket.endpoint.broadcast! CC.chan_room <> socket.assigns.room,
      "update:flex-button", %{username: user.username, html: html, button: "set-remove-moderator"}
    socket
  end

  defp update_mute_unmute_button(socket, channel_id, user, current_user) do
    # Logger.warn "assigns: #{inspect socket.assigns}"
    html =
      Phoenix.View.render_to_string OneChatWeb.FlexBarView,
        "user_card_mute_button.html", [
          channel_id: channel_id,
          user: user,
          current_user: current_user
        ]
    socket.endpoint.broadcast! CC.chan_room <> socket.assigns.room,
      "update:flex-button", %{username: user.username, html: html, button: "mute-unmute"}
  end

end

