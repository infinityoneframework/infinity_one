defmodule OneDialerWeb.Channel.Dialer do

  import InfinityOneWeb.Gettext

  alias InfinityOne.Accounts
  alias Rebel.SweetAlert

  require Logger

  @adapter Application.get_env(:infinity_one, :dialer_adapter, nil)

  # TODO: figure out a way to inject this into the UserChannel
  def dial(socket, %{"dataset" => %{"phone" => number}} = sender) do
    # Logger.warn "dial sender: num: #{number}, #{inspect sender}"
    OneChatWeb.UserChannel.close_phone_cog socket, sender
    dial(socket, number)
  end

  def dial(socket, %{"dataset" => %{"phoneStatus" => username}}) do
    adapter = adapter()
    # IO.inspect username, label: "username...."
    user = Accounts.get_by_user username: username, preload: adapter.user_preload()
    number = adapter.default_extension_number user
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
    |> get_orig_info
    |> OneDialer.dial(number, [])
    socket
  end

  defp get_orig_info(%{user_id: user_id}) do
    adapter = adapter()
    user = Accounts.get_user user_id, preload: adapter.user_preload()
    {user, adapter.default_extension_number(user)}
  end

  defp adapter do
    unless @adapter do
      raise "Feature requires a phone server adapter"
    end
    @adapter
  end

end
