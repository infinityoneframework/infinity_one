defmodule UccChat.Robot.Adapters.UccChat do
  use Hedwig.Adapter

  alias UccChat.Robot.Adapters.UccChat.{Connection}

  @doc false
  def init({robot, opts}) do
    {:ok, conn} = Connection.start(opts)
    # Kernel.send(self(), :connected)
    # {:ok, %{conn: conn, opts: opts, robot: robot}}
    Kernel.send(self(), :connected)
    {:ok, %{conn: conn, opts: opts, robot: robot}}
  end

  def status(pid), do: GenServer.call(pid, :status)

  @doc false
  def handle_cast({:send, msg}, %{conn: conn} = state) do
    Kernel.send(conn, {:reply, msg})
    {:noreply, state}
  end

  @doc false
  def handle_cast({:reply, %{user: _user, text: text} = msg}, %{conn: conn} = state) do
    # Kernel.send(conn, {:reply, %{msg | text: "#{user}: #{text}"}})
    Kernel.send(conn, {:reply, %{msg | text: "#{text}"}})
    {:noreply, state}
  end

  @doc false
  def handle_cast({:emote, msg}, %{conn: conn} = state) do
    Kernel.send(conn, {:reply, msg})
    {:noreply, state}
  end

  @doc false
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_info({:message, %{"text" => text, "user" => user, "channel" => channel}}, %{robot: robot} = state) do
    msg = %Hedwig.Message{
      ref: make_ref(),
      robot: robot,
      text: text,
      type: "chat",
      room: channel,
      user: %Hedwig.User{id: user.id, name: user.name}
    }

    Hedwig.Robot.handle_in(robot, msg)

    {:noreply, state}
  end

  def handle_info(:connected, %{robot: robot} = state) do
    :ok = Hedwig.Robot.handle_connect(robot)
    {:noreply, state}
  end
end
