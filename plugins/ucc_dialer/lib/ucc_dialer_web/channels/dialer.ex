defmodule UccDialerWeb.Channel.Dialer do

  alias UcxUcc.Accounts

  require Logger

  # TODO: figure out a way to inject this into the UserChannel
  def dial(socket, %{"dataset" => %{"phone" => number}} = sender) do
    # Logger.warn "dial sender: num: #{number}, #{inspect sender}"
    UccChatWeb.UserChannel.close_phone_cog socket, sender
    dial(socket, number)
  end

  def dial(socket, %{"dataset" => %{"phoneStatus" => username}}) do
    # IO.inspect username, label: "username...."
    user = Accounts.get_by_user username: username, preload: [:extension]
    dial socket, Map.get(user, :extension, %{}) |> Map.get(:extension)
  end

  def dial(socket, nil) do
    Logger.warn "attempting to call nil number"
    socket
  end

  def dial(socket, number) do
    # IO.inspect number, label: "number...."
    socket.assigns
    |> get_orig_into
    |> UccDialer.dial(number, [])
    socket
  end

  defp get_orig_into(%{user_id: user_id}) do
    user = Accounts.get_user user_id, preload: [:extension]
    exten =
      user
      |> Map.get(:extension, %{})
      |> Map.get(:extension)
    {user, exten}
  end

end
