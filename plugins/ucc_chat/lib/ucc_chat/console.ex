defmodule UccChat.Console do
  @moduledoc """
  Console commands

  ## Command list

  * account/1 - Get account by
  * accounts/1 - Get accounts by
  * channel/1 - Get channel by
  * channels/1 - Get channels  by
  * clear_last_read/0 - Clear all last_read subscription fields
  * message/1 - Get message by
  * messages/1 - Get messages by
  * pubsub/0 - Get UccPubSub state.
  * pubsub/1 - Get pubsub [:subs, :keys, :values]
  * user/1 - Get user by
  * users/1 - Get users by
  """
  alias UccChat.{Subscription}
  alias UcxUcc.Repo
  alias UcxUcc.UccPubSub
  alias UcxUcc.Accounts

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
  Get a user by  opts
  """
  def user(opts), do: Accounts.get_by_user(opts)

  @doc """
  Get users by opts
  """
  def users(opts), do: Accounts.list_by_user(opts)

  @doc """
  Get account by opts
  """
  def account(opts), do: Accounts.get_by_account(opts)

  @doc """
  Get accounts by opts
  """
  def accounts(opts), do: Accounts.list_by_account(opts)

  @doc """
  Get channel by opts
  """
  def channel(opts), do: UccChat.Channel.get_by(opts)

  @doc """
  Get channels by
  """
  def channels(opts), do: UccChat.Channel.list_by(opts)

  @doc """
  Get message by opts.

  """
  def message(opts), do: UccChat.Message.get_by(opts)

  @doc """
  List messages by opts.
  """
  def messages(opts), do: UccChat.Message.list_by(opts)

end
