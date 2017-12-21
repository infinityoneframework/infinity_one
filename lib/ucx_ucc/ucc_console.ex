defmodule UccConsole do

  alias UcxUccWeb.Endpoint
  alias UcxUcc.Accounts

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
  Get a user by username.
  """
  def user(username) do
    Accounts.get_by_user username: username, preload: [:account, :roles, user_roles: :role]
  end

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
end
