defmodule Mscs.ClientsSupervisor do
  @moduledoc """
  Handles the startup and supervision of ClientSm processes

  Use this module to start a new ClientSm. This way, they fit in the
  supervision tree and will get restarted if they fail
  """

  use Supervisor
  require Logger

  #########
  # API

  def start_link do
    Logger.debug "** INIT: Starting #{inspect __MODULE__}"
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  # def start_client(%{mac_address: mac_address} = state) do
  #   id = "client_#{mac_address}"
  #   Logger.debug "#{__MODULE__} Starting: #{id}"
  #   case start_worker(__MODULE__, id, worker(Mscs.ClientSm, [state],
  #                                              id: id, restart: :transient)) do
  #     {:error, {:already_started, pid}} ->
  #       Mscs.ClientAgent.put mac_address, pid
  #       {:ok, pid}
  #     other -> other
  #   end
  # end

  def open_unistim_socket(server_address, server_port, port, recv_func, receiver) do
    id = "unistim_#{port}"
    args = [socket_type: :client, server_address: server_address, server_port:
            server_port, port: port, recv_func: recv_func, receiver: receiver]
    child_spec = worker(Rudp, [args],  id: id, restart: :temporary)
    result = start_worker(__MODULE__, id, child_spec)
    Logger.debug "open_unistim_socket: result #{inspect result}"
    result
  end

  #########
  # Call backs

  def init([]) do
    children = []
    supervise(children, strategy: :one_for_one)
  end

  #########
  # Private

  defp start_worker(name, id, child_spec) do
    Logger.debug "name #{inspect name} id #{inspect id} child_spec #{inspect child_spec}"
    case :supervisor.start_child(name, child_spec) do
      {:error, :already_present} ->
        case :supervisor.delete_child(name, id) do
          :ok ->
           Logger.info "#{__MODULE__} Delete and start child id: #{id}"
            :supervisor.start_child(name, child_spec)
          _ ->
            Logger.info "#{__MODULE__} Could not delete_child. restarting child id: #{id}"
            :supervisor.restart_child(name, id)
        end
     {:error, {:already_started, pid}} ->
       Logger.info "#{__MODULE__}.start_child: already_started #{id} #{inspect pid}"
       {:error, {:already_started, pid}}
      other ->
        Logger.info "#{__MODULE__} start_child #{id} other: #{inspect other}"
        other
    end
  end
end
