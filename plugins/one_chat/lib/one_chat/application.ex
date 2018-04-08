defmodule OneChat.Application do
  @moduledoc """
  The main OneChat Application module.

  Provides:
  * a list of children to be started from the main `InfinityOne.Application`.
  * a start/2 function that is called when the main `InfinityOne.start/2` is run.
  """

  @doc """
  Returns a list of children to be started.
  """
  def children do
    import Supervisor.Spec

    [
      # supervisor(OneChat.Presence, []),
      worker(OneChat.TypingAgent, []),
      worker(OneChat.MessageAgent, []),
      # worker(OneChat.UserAgent, []),
      worker(OneChat.PresenceAgent, []),
      # worker(OneChat.Robot.Adapters.OneChat, []),
      worker(OneChat.Robot, []),
      worker(OneChat.ChannelMonitor, [:chan_system]),
    ]
  end

  def start(_type, _args) do
    OneChatWeb.FlexBar.Defaults.add_buttons()
    OneChatWeb.RoomChannel.KeyStore.initialize()
    spawn fn ->
      # Need time for the app to fully load before compiling the Message Patterns
      Process.sleep(1000)
      OneChat.MessageReplacementPatterns.compile()
    end
  end

end
