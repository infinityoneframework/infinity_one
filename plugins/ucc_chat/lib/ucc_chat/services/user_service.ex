defmodule UccChat.UserService do
  use UccChat.Shared, :service
  # alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.{Subscription, Channel}
  alias UcxUcc.Accounts.Account
  alias Ecto.Multi

  require Logger

  def total_users_count do
    User.total_count() |> Repo.one
  end

  def online_users_count do
    Coherence.CredentialStore.Agent
    |> Agent.get(&(&1))
    |> Map.keys
    |> length
  end

  def get_online_users do
    Coherence.CredentialStore.Agent
    |> Agent.get(&(&1))
    |> Map.values
  end

  def get_all_users do
    User.all() |> Repo.all
  end

  defdelegate open_channel_count(user_id), to: Subscription
  defdelegate open_channels(user_id), to: Subscription

  def delete_user(user) do
    Account
    |> Repo.get(user.account_id)
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
    multi =
      Multi.new
      |> Multi.insert(:account, Account.changeset(%Account{}, %{}))
      |> Multi.run(:user, &do_insert_user(&1, params, opts))
    Repo.transaction(multi)
  end

  defp do_insert_user(%{account: %{id: id}}, params, opts) do
    changeset = User.changeset(%User{}, Map.put(params, "account_id", id))
    case Repo.insert changeset do
      {:ok, user} ->
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
