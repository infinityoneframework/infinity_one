defmodule UccChat.SideNavService do
  use UccChat.Shared, :service

  alias UcxUcc.Accounts
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.{ChatDat, Channel, ChannelService}
  alias UccChat.Schema.Direct, as: DirectSchema
  alias UccChat.Schema.Subscription, as: SubscriptionSchema

  def render_rooms_list_seach(match, user_id, opts \\ [], channel_id \\ nil) do
    user = Helpers.get_user! user_id
    channel = if channel_id, do: Channel.get(channel_id), else: nil

    chatd = ChatDat.new_search(user, match, channel, opts)

    render_to_string UccChatWeb.SideNavView, "rooms_list.html", chatd: chatd
  end

  def render_rooms_list(channel_id, user_id) do
    user = Helpers.get_user! user_id
    channel = if not (is_nil(channel_id) or channel_id == ""), do: Channel.get(channel_id), else: nil

    chatd = ChatDat.new(user, channel)

    render_to_string UccChatWeb.SideNavView, "rooms_list.html", chatd: chatd
  end

  def render_more_channels(user_id) do
    user = Accounts.get_user! user_id, preload: [:roles, user_roles: :role]

    channels = ChannelService.get_side_nav_rooms(user)

    render_to_string UccChatWeb.SideNavView, "list_combined_flex.html",
      channels: channels, current_user: user
  end

  def render_more_users(user_id) do
    {user, users} = get_more_users(user_id)
    render_to_string UccChatWeb.SideNavView, "list_users_flex.html",
      UcxUcc.Hooks.render_users_bindings([users: users, current_user: user])
  end

  def get_more_users(user_id) do
    user = Helpers.get_user! user_id
    preload = UcxUcc.Hooks.user_preload [:roles, user_roles: :role]
    users =
      Repo.all(from u in User,
        left_join: d in DirectSchema, on: u.id == d.user_id and
          d.friend_id == ^(user.id),
        left_join: s in SubscriptionSchema, on: s.user_id == ^user_id and
          s.channel_id == d.channel_id,
        where: u.id != ^user_id,
        order_by: [asc: u.username],
        preload: ^preload,
        select: {u, s})
      |> Enum.reject(fn {user, _} -> Accounts.has_role?(user, "bot") || user.active != true end)
      |> filter_guest(user)
      |> UcxUcc.Hooks.process_user_subscription
      |> Enum.map(fn
        {user, nil} ->
          struct(user, subscription_hidden: nil,
            status: UccChat.PresenceAgent.get(user.id))
        {user, sub} ->
          struct(user, subscription_hidden: sub.hidden,
            status: UccChat.PresenceAgent.get(user.id))
      end)
    {user, users}
  end

  defp filter_guest(list, user) do
    cond do
      Accounts.has_role?(user, "admin") or Accounts.has_role?(user, "user") ->
        list

      Accounts.has_role?(user, "guest") ->
        Enum.reject(list, fn {_, s} -> is_nil(s) end)

      true -> []
    end
  end

end
