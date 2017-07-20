defmodule UccChat.Web.FlexBar.Tab.MembersList do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.Channel
  alias UccChat.Web.FlexBarView
  alias UccChat.Accounts

  require Logger

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel group im],
      id: "members-list",
      title: ~g"Members List",
      icon: "icon-users",
      view: View,
      template: "users_list.html",
      order: 40
    }
  end

  def args(user_id, channel_id, _, opts) do
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

    [users: users, user: user, user_info: user_info,
     channel_id: channel_id, current_user: current_user]
  end

  def user_args(user_id, channel_id, username) do
    channel = Channel.get!(channel_id, preload: [users: :roles])
    [
      user: Helpers.get_user_by_name(username, preload: [:roles]),
      user_info: user_info(channel, user_mode: true, view_mode: true),
      channel_id: channel_id,
      current_user: Helpers.get_user!(user_id)
    ]
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
    channel_id = socket.assigns[:channel_id]

    html = Phoenix.View.render_to_string View, "user_card.html",
      user_args(user_id, channel_id, sender["dataset"]["username"])

    socket
    |> update(:html, set: html, on: "#flex-user-card-details")

    socket
  end

  def view_all(socket, _sender) do
    update(socket, :class, toggle: "animated-hidden",
      on: ".flex-tab-container .user-view")
  end
end

