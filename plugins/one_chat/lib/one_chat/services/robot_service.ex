defmodule OneChat.RobotService do
  require Logger

  def new_message(nil, _channel, _user) do
    :ok
  end
  def new_message(body, channel, user) do
    Kernel.send :robot, {:message, body, channel, user}
  end

end
