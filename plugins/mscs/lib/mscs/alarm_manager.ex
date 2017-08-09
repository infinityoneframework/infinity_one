# Copyright (C) E-MetroTel, 2017 - All Rights Reserved
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of
# a written license agreement with E-MetroTel.


defmodule Mscs.AlarmManager do
  @moduledoc """
  Handle Mscs alarms

  The alarm manager is responsible for managing alarm state for Mscs.
  Alarms are either set or cleared.

  Alarms can be queried in the console with the alarms command. Each active
  alarm is listed with the name of the alarm and a brief description.

  ## Examples

  """

  @timer   10000


  @alarm_list [
    license_check:      { :single, "License Manager", "No WebRTC Client License" },
    unsupported_device: { :multiple, nil, nil },
  ]

  use ExActor.GenServer, export: :alarm_manager
  require Logger

  @doc false
  defstart start_link do
    len = Enum.count(@alarm_list)
    interval = div @timer, len
    Enum.each(1..len, &(:erlang.start_timer(&1 * interval, self, Enum.at(@alarm_list, &1 - 1))))
    initial_state []
  end

  @doc """
  Set a multiple type alarm

  Multiple type alarms are alarms that can have multiple alarms for a single type
  where each alarm is identified by an id. This is the type of alarm used for unsupported
  devices

  ## Example
      Mscs.AlarmManager.set(:unsupported_device, 10, "Unsupported Device", "Device has been disabled")
  """
  defcast set(alarm, id, name, description), state: state do
    set_alarm(state, alarm, id, name, description)
      |> new_state
  end

  @doc """
  Set a single type alarm

  Single type alarms can only have one instance. This is the type of the ftp server alarm

  """
  defcast set(alarm, name, description), state: state do
    set_alarm(state, alarm, name, description)
      |> new_state
  end

  @doc """
  Clear a multiple type alarm

  ## Example
      Mscs.AlarmManager.clear(:unsupported_device, 10)
  """
  defcast clear(alarm, id), state: state do
    clear_alarm(state, alarm, id)
      |> new_state
  end

  @doc """
  Clear a single type alarm

  """
  defcast clear(alarm), state: state do
    clear_alarm(state, alarm)
      |> new_state
  end

  @doc """
  Print all active alarms
  """
  defcast print, state: state do
    get_alarms(state)
      |> Enum.each(&(IO.puts &1))
    noreply
  end

  @doc """
  Clear all alarms

  Used mostly for testing
  """
  defcast clear_all do
    new_state []
  end

  @doc """
  Returns a string of the alarms
  """
  defcall alarms, state: state do
    get_alarms(state)
    |> Enum.map(&(&1))
    |> reply
  end

  @doc """
  Returns current alarm list of strings
  """
  defcall get, state: state do
    get_alarms(state)
      |> reply
  end

  @doc """
  Returns the current AlarmManager state

  Used mostly for testing
  """
  defcall get_state, state: state, do: reply(state)

  def handle_info({:timeout, _ref, data}, state) do
    :erlang.start_timer(@timer, self, data)
    new_state handle_alarm(state, data)
  end

  ################
  # Alarm Handlers

  def license_check() do
    Ucx.LicenseManager.licensed?(:MSC) == false
  end

  @doc """
  The unsupported device alarm handler

  Checks existing alarms and clears them if the device is enabled.
  """
  def unsupported_device(id) do
    Logger.info "#{__MODULE__} unsupported #{inspect id}"
    true
  end

  ###########
  # Helpers

  @doc false
  def get_alarms(state) do
    for {_key, value} <- state do
      case value do
        {name, description} ->
          "#{name}: #{description}"
        hash ->
          get_alarms HashDict.to_list(hash)
      end
    end
    |> List.flatten
    |> Enum.sort
  end

  @doc false
  def handle_alarm(state, data) do
    case data do
      {alarm, {:single, name, description}} ->
        check_alarm(state, alarm, name, description)

      {alarm, {:multiple, _name, _description}} ->
        Keyword.get(state, alarm, HashDict.new)
        |> Enum.reduce(state, fn({id, {name, description}}, acc) ->
          check_alarm(acc, alarm, id, name, description)
        end)
    end
  end

  defp check_alarm(state, alarm, name, description) do
    if apply(__MODULE__, alarm, []) do
      set_alarm(state, alarm, name, description)
    else
      clear_alarm(state, alarm)
    end
  end

  defp check_alarm(state, alarm, id, name, description) do
    if apply(__MODULE__, alarm, [id]) do
      set_alarm(state, alarm, id, name, description)
    else
      clear_alarm(state, alarm, id)
    end
  end

  defp set_alarm(state, alarm, name, description) do
    validate_alarm alarm
    if name do
      Keyword.put state, alarm, {name, description}
    else
      state
    end
  end

  @doc false
  def set_alarm(state, alarm, id, name, description) do
    validate_alarm alarm
    if name do
      list = Keyword.get(state, alarm, HashDict.new)
      |> HashDict.put(id, {name, description})
      Keyword.put(state, alarm, list)
    else
      state
    end
  end

  defp clear_alarm(state, alarm, id) do
    validate_alarm alarm
    case Keyword.get(state, alarm) do
      nil -> state
      hash ->
        new_hash = HashDict.delete(hash, id)
        if HashDict.size(new_hash) == 0 do
          Keyword.delete(state, alarm)
        else
          Keyword.put(state, alarm, new_hash)
        end
    end
  end

  defp clear_alarm(state, alarm) do
    validate_alarm alarm
    Keyword.delete state, alarm
  end

  defp validate_alarm(alarm) do
    unless Keyword.get(@alarm_list, alarm), do: raise("Invalid Alarm")
  end

end

