Code.ensure_compiled UccChat.Robot.Adapters.UccChat
defmodule UccChat.Robot do
  use Hedwig.Robot, otp_app: :ucx_ucc

  alias UcxUcc.UccPubSub
  require Logger

  def handle_connect(%{name: name} = state) do
    if :undefined == :global.whereis_name(name) do
      :yes = :global.register_name(name, self())
    end
    UccPubSub.subscribe("message:new")
    super(state)
  end

  def handle_disconnect(_reason, state) do
    UccPubSub.unsubscribe("message:new")
    {:reconnect, 5000, state}
  end

  def handle_in(%Hedwig.Message{} = msg, state) do
    {:dispatch, msg, state}
  end

  def handle_in(_msg, state) do
    {:noreply, state}
  end

  def handle_info({"message:new", "channel:" <> _, %{message: message}}, state) do
    if message.channel.type != 2 and !message.system do
      UccChat.RobotService.new_message(message.body, message.channel, message.user)
    end
    {:noreply, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end
end
