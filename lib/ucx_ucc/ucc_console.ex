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

end
