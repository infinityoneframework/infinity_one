defmodule UccDialerWeb.Channel.Dialer do

  import UcxUccWeb.Gettext

  alias UcxUcc.Accounts
  alias Rebel.SweetAlert

  require Logger

  # TODO: figure out a way to inject this into the UserChannel
  def dial(socket, %{"dataset" => %{"phone" => number}} = sender) do
    # Logger.warn "dial sender: num: #{number}, #{inspect sender}"
    UccChatWeb.UserChannel.close_phone_cog socket, sender
    dial(socket, number)
  end

  def dial(socket, %{"dataset" => %{"phoneStatus" => username}}) do
    # IO.inspect username, label: "username...."
    user = Accounts.get_by_user username: username, preload: [:extensions]
    number = extension user
    title = gettext "Call %{user}", user: user.username
    confirm_message = gettext "Place call to %{number}?", number: number
    icon = "phone"

    SweetAlert.swal_modal socket, ~s(<i class="icon-#{icon} alert-icon success-color"></i>#{title}), confirm_message, nil,
      [html: true, showCancelButton: true, closeOnConfirm: true, closeOnCancel: true],
      confirm: fn _result ->
        dial socket, number

        SweetAlert.swal socket,
          ~g"Calling!",
          gettext("Dialing %{user}", user: user.username),
          "success",
          timer: 2000,
          showConfirmButton: false
        true
      end,
      cancel: fn _result ->
        true
      end

  end

  def dial(socket, nil) do
    Logger.warn "attempting to call nil number"
    socket
  end

  def dial(socket, number) do
    socket.assigns
    |> get_orig_into
    |> UccDialer.dial(number, [])
    socket
  end

  defp get_orig_into(%{user_id: user_id}) do
    user = Accounts.get_user user_id, preload: [:extension]
    {user, extension(user)}
  end

  # TODO: This needs to be refactored for the extensions change
  defp extension(user) do
    user
    |> Map.get(:extensions, [])
    |> hd
    |> Map.get(:extension)
  end

end
