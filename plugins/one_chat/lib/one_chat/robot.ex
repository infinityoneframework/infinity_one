Code.ensure_compiled OneChat.Robot.Adapters.OneChat
defmodule OneChat.Robot do
  @moduledoc """
  The implementation of the OneChat chat bot.

  A service that handles passing incoming messages to the registered
  bots.
  """
  use Hedwig.Robot, otp_app: :infinity_one

  alias InfinityOne.OnePubSub
  require Logger

  def handle_connect(%{name: name} = state) do
    if :undefined == :global.whereis_name(name) do
      :yes = :global.register_name(name, self())
    end
    OnePubSub.subscribe("message:new")
    super(state)
  end

  def handle_disconnect(_reason, state) do
    OnePubSub.unsubscribe("message:new")
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
      OneChat.RobotService.new_message(message.body, message.channel, message.user)
    end
    {:noreply, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end
end
