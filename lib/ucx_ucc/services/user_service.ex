defmodule UcxUcc.UserService do
  use UcxUcc.Web, :service
  # alias UcxChat.ServiceHelpers, as: Helpers
  alias UcxUcc.{Repo, Accounts}
  alias Accounts.{User, Account}
  alias UccChat.Schema.Channel, as: ChannelSchema
  alias UccChat.Subscription
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

  def get_all_users do
    User.all() |> Repo.all
  end

  def delete_user(user) do
    Account
    |> Repo.get(user.account_id)
    |> Account.changeset
    |> Repo.delete
  end

  def insert_user(params, opts \\ []) do
    multi =
      Multi.new
      |> Multi.insert(:user, User.changeset(%User{}, params))
      |> Multi.run(:role, &do_insert_user_role/1)
      |> Multi.run(:account, &do_insert_account/1)
      |> Multi.run(:callback, &do_callback(&1, params, opts))
    Repo.transaction(multi)
  end

  defp do_insert_user_role(%{user: user} = _changes) do
    Accounts.add_role_to_user(user, "user")
  end

  defp do_insert_account(%{user: %{id: user_id}}) do
     Accounts.create_account(%{user_id: user_id})
  end

  defp do_callback(changes, params, opts) do
    if !!Application.get_env(:ucc_chat, :module, false) and
     opts[:callback] != false do
      (opts[:callback] ||
        &UccChat.Accounts.insert_user_default_channels/3).(changes, params, opts)
    else
      {:ok, changes}
    end
  end
end
