defmodule UccConsole do
  @moduledoc """
  Console commands

  ## Command list

  * account/1 - Get account by
  * accounts/1 - Get accounts by
  * channel/1 - Get channel by
  * channel_name/1
  * channels/1 - Get channels  by
  * clear_last_read/0 - Clear all last_read subscription fields
  * js/2 - Run Javascript in the browser
  * js/3 - Run Javascript in the browser
  * message/1 - Get message by
  * messages/1 - Get messages by
  * pubsub/0 - Get UccPubSub state.
  * pubsub/1 - Get pubsub [:subs, :keys, :values]
  * user/1 - Get user by username of ops
  * users/1 - Get users by
  """
  alias UccChat.{Subscription}
  alias UcxUcc.Repo
  alias UcxUcc.UccPubSub
  alias UcxUcc.Accounts
  alias UcxUccWeb.Endpoint

  require UccChat.ChatConstants, as: CC

  @doc """
  Run javascript on the browser, give a username
  """
  def js(username, js) do
    case Accounts.get_by_user username: username do
      nil ->
        "User not found"
      user ->
        js :user, user.id, js
    end
  end

  def js(channel, ch_id, js) when channel in [:user, :room, :rtc, :system, :webrtc] do
    Endpoint.broadcast channel_name(channel) <> ch_id, "js:execjs", %{js: js, sender: self()}
    receive do
      {:response, response} -> response
      {:error, error} -> {:error, error}
    end
  end

  defp channel_name(:rtc), do: channel_name(:webrtc)
  defp channel_name(:webrtc), do: CC.chan_webrtc <> "user-"
  defp channel_name(:user), do: CC.chan_user
  defp channel_name(:room), do: CC.chan_room

  @doc """
  Set the runtime log level

  ## Examples

      UccConsole.log_level :debug
      :ok
  """
  @spec log_level(atom) :: :ok
  def log_level(level) when level in ~w(none error warn info debug)a do
    Logger.configure level: level
  end

  @doc """
  Get the current log level.

      UccConsole.log_level()
      :info
  """
  @spec log_level() :: atom
  def log_level do
    Logger.level
  end

  @doc """
  Get the subscription for a given username and channel name

      iex> UccConsole.subscription "admin", "general"

      %UccChat.Schema.Subscription{__meta__: #Ecto.Schema.Metadata<:loaded, "subscriptions">,
        alert: false,
        channel: #Ecto.Association.NotLoaded<association :channel is not loaded>,
        channel_id: "b29fe176-64aa-44ba-86de-e846eaf39865",
        current_message: "20180123030942207911", f: false, has_unread: false,
        hidden: false, id: "e51cb56b-f388-45e1-9537-c1e31ec7b1a3",
        inserted_at: #DateTime<2018-01-20 16:30:03.000000Z>,
        last_read: "20180123030942207911", ls: nil, open: false, type: 0, unread: 0,
        updated_at: #DateTime<2018-01-23 04:04:02.000000Z>,
        user: #Ecto.Association.NotLoaded<association :user is not loaded>,
        user_id: "349a35e5-f7c0-40ee-b150-d43e925be789"}
  """
  @spec subscription(username :: String.t, room :: String.t) :: struct
  def subscription(username, room) do
    with %{} = user <- Accounts.get_by_username(username),
         %{} = channel <- UccChat.Channel.get_by(name: room) do
      UccChat.Subscription.get_by user_id: user.id, channel_id: channel.id
    end
  end

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
  Get a user by username or by opts
  """
  def user(username) when is_binary(username) do
    Accounts.get_by_user username: username, preload: [:account, :roles, user_roles: :role]
  end

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
  def accounts(opts), do: Accounts.list_by_accounts(opts)

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
