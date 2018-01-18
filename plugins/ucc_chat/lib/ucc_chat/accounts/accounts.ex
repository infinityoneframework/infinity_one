defmodule UccChat.Accounts do

  alias UccChat.{PresenceAgent, Channel, Subscription}
  alias UcxUcc.Accounts
  alias Accounts.Account
  alias UcxUcc.{Repo, Hooks}

  def get_all_channel_online_users(channel) do
    channel
    |> get_all_channel_users
    |> Enum.reject(&(&1.status == "offline"))
  end

  def get_all_channel_users(channel) do
    Enum.map(channel.users, fn user ->
      user
      |> struct(status: PresenceAgent.get(user.id))
      |> Hooks.preload_user([])
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

  @doc """
  Gets the status message history list.

  Retrieves the list 0 separated string field and and returns it as a
  list of binaries.
  """
  def get_status_message_history(%Account{status_message_history: history}) do
    history
    |> String.split(<<0::8>>)
    |> tl
  end

  @doc """
  Updates a user's status message.

  Updates the user's status message and adds it to the user's history
  if it does not already exist.
  """
  def update_status_message(%Account{} = account, "") do
    Accounts.update_account(account, %{status_message: ""})
  end

  def update_status_message(%Account{} = account, message) do
    message = String.trim(message)
    attrs =
      account
      |> get_status_message_history()
      |> Enum.any?(& &1 == message )
      |> case do
        true -> %{}
        false -> %{status_message_history: account.status_message_history <> <<0::8, message::binary>>}
      end
      |> Map.put(:status_message, message)

    Accounts.update_account(account, attrs)
  end
end
