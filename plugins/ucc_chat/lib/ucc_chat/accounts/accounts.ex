defmodule UccChat.Accounts do

  alias UccChat.{PresenceAgent, Channel, Subscription}
  alias UcxUcc.Accounts.Account
  alias UcxUcc.Repo

  def get_all_channel_online_users(channel) do
    channel
    |> get_all_channel_users
    |> Enum.reject(&(&1.status == "offline"))
  end

  def get_all_channel_users(channel) do
    Enum.map(channel.users, fn user ->
      struct(user, status: PresenceAgent.get(user.id))
    end)
  end

  def get_channel_offline_users(channel) do
    channel
    |> get_all_channel_users
    |> Enum.filter(&(&1.status == "offline"))
  end

  def user_info(channel, opts \\ []) do
    %{
      direct: opts[:direct] || false,
      show_admin: opts[:admin] || false,
      blocked: channel.blocked,
      user_mode: opts[:user_mode] || false,
      view_mode: opts[:view_mode] || false
    }
  end

  def get_account_by_user_id(user_id, opts \\ []) do
    preload = opts[:preload]
    account =
      user_id
      |> Account.get()
      |> Repo.one()
    case preload do
      nil     -> account
      preload -> Repo.preload account, preload
    end
  end

  def insert_user_default_channels(%{user: user} = changes, _params, opts) do
    if opts[:join_default_channels] do
      [default: true]
      |> Channel.list_by()
      |> Enum.each(fn ch ->
        Subscription.create!(%{channel_id: ch.id, user_id: user.id})
      end)
    end
    {:ok, changes}
  end
end
