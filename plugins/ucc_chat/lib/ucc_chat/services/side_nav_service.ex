defmodule UccChat.SideNavService do
  use UccChat.Shared, :service

  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.{ChatDat, Channel, ChannelService}
  alias UccChat.Schema.Direct, as: DirectSchema
  alias UccChat.Schema.Subscription, as: SubscriptionSchema

  def render_rooms_list(channel_id, user_id) do
    user = Helpers.get_user! user_id
    channel = if channel_id, do: Channel.get(channel_id), else: nil

    chatd = ChatDat.new(user, channel)

    "rooms_list.html"
    |> UccChatWeb.SideNavView.render(chatd: chatd)
    |> Helpers.safe_to_string
  end

  def render_more_channels(user_id) do
    user = Helpers.get_user! user_id
    channels = ChannelService.get_side_nav_rooms user

    "list_combined_flex.html"
    |> UccChatWeb.SideNavView.render(channels: channels, current_user: user)
    |> Helpers.safe_to_string
  end

  def render_more_users(user_id) do
    user = Helpers.get_user! user_id
    has_extension? = UccChat.phone_status?
    preload = user_preload(has_extension?)
    users =
      Repo.all(from u in User,
        left_join: d in DirectSchema, on: u.id == d.user_id and
          d.users == ^(user.username),
        left_join: s in SubscriptionSchema, on: s.user_id == ^user_id and
          s.channel_id == d.channel_id,
        # left_join: c in Channel, on: c.id == d.channel_id,
        where: u.id != ^user_id,
        order_by: [asc: u.username],
        preload: ^preload,
        select: {u, s})
      |> Enum.reject(fn {user, _} -> User.has_role?(user, "bot") || user.active != true end)
      |> load_phone_status(has_extension?)
      |> Enum.map(fn
        {user, nil} ->
          struct(user, subscription_hidden: nil,
            status: UccChat.PresenceAgent.get(user.id))
        {user, sub} ->
          struct(user, subscription_hidden: sub.hidden,
            status: UccChat.PresenceAgent.get(user.id))
      end)
    bindings = [users: users, current_user: user]
    bindings = if has_extension?, do: [{:phone_status, true} | bindings],
      else: bindings
    "list_users_flex.html"
    |> UccChatWeb.SideNavView.render(bindings)
    |> Helpers.safe_to_string
  end

  defp load_phone_status(users, false) do
    users
  end

  defp load_phone_status(users, true) do
    Enum.map(users, fn {user, other} ->
      if user.extension do
        # {struct(user, extension: Map.put(user.extension, :status, status)), other}
        {UcxPresence.set_status(user), other}
      else
        {user, other}
      end
    end)
  end

  defp user_preload(true), do: [:roles, :extension]
  defp user_preload(false), do: [:roles]

end
