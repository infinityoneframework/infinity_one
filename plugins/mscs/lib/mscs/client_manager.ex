defmodule Mscs.ClientManager do
  @moduledoc """
  System wide client manager functions.

  Functions to act on the complete set of ClientSMs system wide.
  """
  require Logger
  alias Mscs.ClientSm
  alias Ucx.LicenseManager
  alias Mscs.ClientAgent
  alias Mscs.SystemAgent

  @doc """
  Notify next unlicensed SM so they can pickup the just freed license.
  """
  def notify_unlicensed do
    case SystemAgent.get :unlicensed do
      [mac | _] -> 
        case ClientAgent.get mac do
          nil -> :ok
          pid -> ClientSm.check_license(pid)
        end
      _ -> 
        :ok
    end
  end

  @doc """
  LicenseManger call back to notify change in license status.

  Notify all ClientSm when a change in license status occurs.
  """
  def license_change(settings) do
    Logger.info "license_change settings: #{inspect settings}"
    spawn fn -> 
      count = case LicenseManager.get_option_count(:MSC) do
        {:ok, count} -> count
        _            -> 0
      end
      Logger.info "License count #{count}"
      for pid <- ClientAgent.get |> Dict.values do
        ClientSm.license_change(pid, settings, count)
      end
    end
  end
  
  ###########
  # SystemAgent licensing helpers 

  @doc """
  Is mac address consuming a license?
  """
  def licensed?(mac) do
    licensed? :licensed, mac
  end

  @doc """
  Helper to check licensed or unlicensed status.

  Pass key as :licensed or :unlicensed
  """
  def licensed?(key, mac) do
    Enum.any? SystemAgent.get(key), &(&1 == mac)
  end

  @doc """
  Put mac address into licensed queue.
  """
  def put_licensed(mac) do
    put_licensed :licensed, mac
  end

  @doc """
  Helper to put mac in either licensed or unlicensed
  """
  def put_licensed(key, mac) do
    SystemAgent.update key, fn(x) -> 
      unless mac in x, do: [mac | x], else: x
    end
  end

  def check_and_set_licensed(mac) do
    case Ucx.LicenseManager.get_option_count(:MSC) do
      {:ok, count} -> 
        pid = self
        SystemAgent.update :licensed, fn(list) -> 
          {ret_value, result} = cond do 
            mac in list -> 
              {:ok, list}
            Enum.count(list) < count -> 
              {:ok, [mac | list]}
            true -> 
              {:error, list}
          end
          send pid, ret_value
          result
        end
        receive do
          :ok -> :ok
          :error -> :error 
        end
      other -> 
        other
    end
  end

  @doc """
  Delete mac address from licensed queue.
  """
  def delete_licensed(mac) do
    delete_licensed(:licensed, mac)
  end

  @doc """
  Helper to delete mac from licensed or unlicensed queue.
  """
  def delete_licensed(key, mac) do
    SystemAgent.update key, &(Enum.filter(&1, fn(x) -> x != mac end))
  end

  @doc """
  Get count in licensed queue.
  """
  def licensed_count do
    licensed_count :licensed
  end

  @doc """
  Helper to get count of either licensed or unlicensed queue.
  """
  def licensed_count(key) do
    Enum.count SystemAgent.get(key)
  end

  @doc """
  Is mac address waiting on a license?
  """
  def unlicensed?(mac) do
    licensed? :unlicensed, mac
  end

  @doc """
  Add mac to the unlicensed queue.
  """
  def put_unlicensed(mac) do
    put_licensed :unlicensed, mac
  end

  @doc """
  Delete mac address from unlicensed queue.
  """
  def delete_unlicensed(mac) do
    delete_licensed(:unlicensed, mac)
  end

  @doc """
  Get number in unlicensed queue.
  """
  def unlicensed_count do
    licensed_count :unlicensed
  end

  @doc """
  Move mac address from unlicensed queue to licensed queue.
  """
  def license_unlicensed(mac) do
    move_license(:unlicensed, :licensed, mac)
  end

  @doc """
  Helper to move mac between licensed/unlicensed queues.
  """
  def move_license(source, dest, mac) do
    SystemAgent.update fn(state) -> 
      state
      |> Map.put(source, Map.get(state, source) |> Enum.filter(&(&1 != mac)))
      |> Map.put(dest, [mac | Map.get(state, dest)])
    end
  end

  def put_recovering(mac, recovery, callback) do
    SystemAgent.put :recovering, mac, true 
    spawn fn -> 
      Logger.debug "Staring #{recovery} msecs for #{mac}"
      :timer.sleep(recovery)
      delete_recovering(mac)
      Logger.debug "Recovery period over for #{mac}"
      callback.(mac)
    end
  end

  def get_recovering(mac) do
    SystemAgent.get :recovering, mac
  end

  def delete_recovering(mac) do
    SystemAgent.delete :recovering, mac
  end

end
