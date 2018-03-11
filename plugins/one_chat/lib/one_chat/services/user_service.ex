defmodule OneChat.UserService do
  use OneChat.Shared, :service
  # alias OneChat.ServiceHelpers, as: Helpers
  alias OneChat.{Subscription, Channel, ChannelMonitor}
  alias InfinityOne.Accounts
  alias Accounts.Account
  alias InfinityOne.Coherence.Schemas
  alias Ecto.Multi

  require Logger

  def total_users_count do
    User.total_count() |> Repo.one
  end

  def online_users_count do
    length ChannelMonitor.get_users
  end

  def get_online_users do
    Enum.map ChannelMonitor.get_users, &Schemas.get_user/1
  end

  def get_all_users do
    User.all() |> Repo.all
  end

  defdelegate open_channel_count(user_id), to: Subscription
  defdelegate open_channels(user_id), to: Subscription

  def delete_user(user) do
    Account
    |> Repo.get(user.account.id)
    |> Account.changeset
    |> Repo.delete
  end

  def deactivate_user(user) do
    activate_deactivate_user(user, false)
  end

  def activate_user(user) do
    activate_deactivate_user(user, true)
  end

  defp activate_deactivate_user(user, state) do
    user
    |> Subscription.get_by_user_and_type(2)
    |> Enum.each(fn channel ->
      Channel.update(channel, %{active: state})
    end)
    user
  end

  def insert_user(params, opts \\ []) do
    params
    |> add_user(opts)
    |> Repo.transaction()
  end

  def add_user(params, opts \\ []) do
    Multi.new
    |> Multi.insert(:account, Account.changeset(%Account{}, %{}))
    |> Multi.run(:user, &do_insert_user(&1, params, opts))
  end

  defp do_insert_user(%{account: %{id: id}}, params, opts) do
    changeset = User.changeset(%User{}, params)
    case Repo.insert changeset do
      {:ok, user} ->
        id
        |> Accounts.get_account
        |> Account.changeset(%{user_id: id})
        |> Repo.update

        %UserRole{}
        |> UserRole.changeset(%{user_id: user.id, role: "user"})
        |> Repo.insert!

        unless opts[:join_default_channels] == false do
          true
          |> Channel.list_by_default
          |> Enum.each(fn ch ->
            Subscription.create!(%{channel_id: ch.id, user_id: user.id})
          end)
        end
        {:ok, user}
      error ->
        error
    end
  end
end
