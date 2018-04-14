defmodule OneChat do
  @moduledoc """
  The chat plug-in for InfinityOne.

  Adds team chat functionality to the InfinityOne framework.
  """
  alias InfinityOne.OnePubSub
  alias InfinityOne.Accounts


  # TODO: I don't think this is needed anymore. Check and remove if possible.
  @doc false
  def phone_status? do
    !! Application.get_env :ucx_presence, :enabled
  end

  @doc """
  Refresh presence status and status message for a list of users.

  Call this function from :message_replacement_patterns to update the presence
  status and status messages for newly ported messages containing the appropriate
  markup.

  This function is intended to be called from the :message_replacement_patterns
  processor in `OneChatWeb.MessageView`. It is called with the output of of a
  `Regex.scan`.

  The input will be a list of two element lists with the username contained in
  the second element of the sublist.

  It can also be called with just the username. In this case, it broadcasts the
  payload to `"user:all", "status:refresh-user"` using `InfinityOne.OnePubSub`.
  """
  def refresh_users_status(list) when is_list(list) do
    spawn fn ->
      Process.sleep(1000)
      Enum.each(list, fn [_, username] ->
        refresh_users_status(username)
        # Server.refresh_username(username)
      end)
    end
  end

  def refresh_users_status(username) when is_binary(username) do
    with false <- is_nil(username),
         user_id when not is_nil(user_id) <- Accounts.user_id_by_username(username) do
      OnePubSub.broadcast "user:all", "status:refresh-user", %{username: username, user_id: user_id}
    end
  end

end
