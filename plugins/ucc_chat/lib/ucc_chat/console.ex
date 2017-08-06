defmodule UccChat.Console do
  @moduledoc """
  Console commands

  ## List
  * ca
  * ftab
  """
  alias UccChat.{Subscription}
  alias UcxUcc.Repo
  alias UcxUcc.UccPubSub
  alias UcxUcc.Accounts
  alias Accounts.User

  @doc """
  Clear all last_read subscription fields
  """
  def clear_last_read do
    Subscription
    |> Repo.update_all(set: [last_read: "", current_message: ""])
  end

  @doc """
  Get UccPubSub state.
  """
  def pubsub do
    UccPubSub.state
  end

  @doc """
  Get pubsub items

  ## Arguments

  * `:keys`
  * `:values`
  * `:subs`
  """
  def pubsub(:subs) do
    pubsub() |> Map.get(:subscriptions)
  end
  def pubsub(:keys) do
    pubsub(:subs) |> Map.keys
  end
  def pubsub(:values) do
    pubsub(:subs) |> Map.values
  end

  @doc """
  Get a user by username
  """
  @spec get_by_username(username :: String.t) :: User.t
  def get_by_username(username) do
    Accounts.get_by_user username: username
  end
end
