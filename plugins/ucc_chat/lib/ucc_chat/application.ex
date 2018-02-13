defmodule UccChat.Application do
  @moduledoc """
  The main UccChat Application module.

  Provides:
  * a list of children to be started from the main `UcxUcc.Application`.
  * a start/2 function that is called when the main `UcxUcc.start/2` is run.
  """

  @doc """
  Returns a list of children to be started.
  """
  def children do
    import Supervisor.Spec

    [
      # supervisor(UccChat.Presence, []),
      worker(UccChat.TypingAgent, []),
      worker(UccChat.MessageAgent, []),
      # worker(UccChat.UserAgent, []),
      worker(UccChat.PresenceAgent, []),
      # worker(UccChat.Robot.Adapters.UccChat, []),
      worker(UccChat.Robot, []),
      worker(UccChat.ChannelMonitor, [:chan_system]),
    ]
  end

  @doc """
  Code to be run when the application starts.
  """
  def start(_type, _args) do
    UccChatWeb.FlexBar.Defaults.add_buttons()
    UccChatWeb.RoomChannel.KeyStore.initialize()
  end

end
