defmodule UccChat.Accounts do
  import Ecto.Changeset
  import UcxUccWeb.Gettext

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

  def delete_status_message(%Account{} = account, index) do
    history_list = get_status_message_history(account)
    deleted_message = Enum.at history_list, index

    history =
      history_list
      |> List.delete_at(index)
      |> Enum.join(<<0::8>>)
      |> case do
        "" -> ""
        other -> <<0::8>> <> other
      end

    attrs =
      (account.status_message == deleted_message)
      |> if do
        %{status_message: ""}
      else
        %{}
      end
      |> Map.put(:status_message_history, history)

    Accounts.update_account(account, attrs)
  end

  def replace_status_message(%Account{} = account, index, message) do
    history_list = get_status_message_history(account)
    current_message = Enum.at history_list, index

    history =
      history_list
      |> List.replace_at(index, message)
      |> Enum.join(<<0::8>>)
      |> case do
        "" -> ""
        other -> <<0::8>> <> other
      end

    attrs =
      (account.status_message == current_message)
      |> if do
        %{status_message: ""}
      else
        %{}
      end
      |> Map.put(:status_message_history, history)

    Accounts.update_account(account, attrs)
  end

  @doc """
  Check if the given user is the last owner of any room.

  Give a user with preloaded user_roles, returns a list of room_ids where the user
  is the owner of the room. Otherwise, return false.
  """
  def user_last_owner_of_any_rooms(%{user_roles: user_roles}) when is_list(user_roles) do
    with owners when owners != [] <- Enum.filter(user_roles, & &1.role.name == "owner"),
         singles <- Enum.filter(owners, &Accounts.count_user_roles(&1.role, &1.scope) == 1),
         list when list != [] <- Enum.map(singles, & &1.scope) do
      list
    else
      _ -> false
    end
  end

  def last_admin? do
    role = Accounts.get_role_by_name("admin")
    Accounts.count_user_roles(role) == 1
  end

  def delete_user(%{} = user) do
    changeset = Accounts.change_user(user)

    cond do
      ids = user_last_owner_of_any_rooms(user) ->
        {:error, add_error(changeset, :roles, ~g(Can't delete last owner), room_ids: ids)}
      last_admin?() ->
        {:error, add_error(changeset, :roles, ~g(Can't delete last admin))}
      true ->
        Accounts.delete_user(user)
    end
  end
end
