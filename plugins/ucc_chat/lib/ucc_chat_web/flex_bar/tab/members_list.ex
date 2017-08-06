defmodule UccChatWeb.FlexBar.Tab.MembersList do
  use UccChatWeb.FlexBar.Helpers

  alias UccChat.Channel
  alias UccChatWeb.FlexBarView
  alias UccChat.Accounts
  alias TabBar.Ftab
  alias TabBar.Tab
  alias UccWebrtWeb.FlexBar.Tab.MembersList, as: WebrtcMembersList

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

  def args(socket, user_id, channel_id, _, opts) do
    current_user = Helpers.get_user!(user_id)
    channel = Channel.get!(channel_id, preload: [users: :roles])

    {user, user_mode} =
      case opts["username"] do
        nil ->
          {Helpers.get_user!(user_id), false}
        username ->
          {Helpers.get_user_by_name(username, preload: [:roles]), true}
      end

    users = Accounts.get_all_channel_online_users(channel)

    total_count = channel.users |> length

    user_info =
      channel
      |> user_info(user_mode: user_mode, view_mode: true)
      |> Map.put(:total_count, total_count)

    {[users: users, user: user, user_info: user_info,
     channel_id: channel_id, current_user: current_user], socket}
  end

  def user_args(socket, user_id, channel_id, username) do
    channel = Channel.get!(channel_id, preload: [users: :roles])
    {[
      user: Helpers.get_user_by_name(username, preload: [:roles]),
      user_info: user_info(channel, user_mode: true, view_mode: true),
      channel_id: channel_id,
      current_user: Helpers.get_user!(user_id)
    ], socket}
  end

  # this is needed since we are overriding below
  def open(socket, user_id, channel_id, tab, nil) do
    super(socket, user_id, channel_id, tab, nil)
  end

  # TODO: Figure out how to have this detect this.
  def open(socket, current_user_id, channel_id, tab, %{"view" => "video"} = args) do
    WebrtcMembersList.open(socket, current_user_id, channel_id, tab, args)
  end

  def open(socket, user_id, channel_id, tab, %{"view" => "user"} = args) do
    username = args["username"]

    {args, socket} = user_args(socket, user_id, channel_id, username)

    html =
      View
      |> Phoenix.View.render_to_string("user_card.html", args)
      |> String.replace(~s('), ~s(\\'))
      |> String.replace("\n", " ")

    selector = ".flex-tab-container .user-view"

    socket
    |> super(user_id, channel_id, tab, nil)
    |> exec_js(~s/$('#{selector}').replaceWith('#{html}'); Rebel.set_event_handlers('#{selector}')/)

    socket
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
    exec_js(socket,
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
        apply tab.module, :open, [socket, user_id, channel_id, tab, args]
      end
  end

  def view_all(%{assigns: assigns} = socket, _sender) do
    TabBar.close_view assigns.user_id, assigns.channel_id, "members-list"

    update(socket, :class, toggle: "animated-hidden",
      on: ".flex-tab-container .user-view")
  end

end

