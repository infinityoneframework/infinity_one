defmodule UccChat.Robot.Adapters.UccChat.Connection do
  @moduledoc false
  use GenServer

  alias UccChat.Robot.Adapters.UccChat.{Connection}

  @name :robot

  require Logger

  defstruct name: nil, owner: nil, user: nil

  def start(opts) do
    name = Keyword.get(opts, :name)
    # user = Keyword.get(opts, :user, get_system_user())
    user = nil

    GenServer.start(__MODULE__, {self(), name, user}, name: @name)
  end

  def status(), do: GenServer.call(@name, :status)


  def init({owner, name, user}) do
    GenServer.cast(self(), :after_init)
    {:ok, %Connection{name: name, owner: owner, user: user}}
  end

  def handle_cast(:after_init, state) do
    {:noreply, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:reply, %{text: text, room: room, user: %{id: user_id, name: _name}}}, %{} = state) do
    body = if Regex.match? ~r/^http.+?(jpg|jpeg|png|gif)$/, text do
      # body = String.replace(text, ~r/^https?:\/\//, "")
      ~s(<img src="#{text}" class="bot-img">)
    else
      text
    end
    # this is where we send a message to the users.
    # need to figure out if this is a private message, or a channel message
    # Logger.error "reply text: #{inspect text} "
    UccChatWeb.RoomChannel.broadcast_bot_message room, user_id, body
    {:noreply, state}
  end

  @doc false
  def handle_info({:message, text, channel, user}, %{owner: owner} = state) do
    Logger.debug fn -> "message text: #{inspect text}, channel.id: #{inspect channel.id}" end
    spawn fn ->
      :timer.sleep 200
      Kernel.send(owner, {:message, %{"text" => text, "user" => user, "channel" => channel}})
    end
    {:noreply, state}
  end

end
