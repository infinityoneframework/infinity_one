# Copyright (C) E-MetroTel, 2017 - All Rights Reserved
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of
# a written license agreement with E-MetroTel.


defmodule Mscs.MscsAlarmManager do
  @moduledoc """
  Handle Mscs alarms

  The alarm manager is responsible for managing alarm state for Mscs.
  Alarms are either set or cleared.

  Alarms can be queried in the console with the alarms command. Each active
  alarm is listed with the name of the alarm and a brief description.

  For WebRTCClient alarms:
  module name: Mscs
  event_id: 401 to 499
  severity: Critical = 1, Warning = 2, Minor = 3, Info = 4
  description: text string upto 120 characters
  action: text string upto 120 characters
  acknowledge: 0 or 1

  """

  use Ucx.AlarmManager
  require Logger

  ################
  # Alarm Handlers

  def license_check() do
    Ucx.LicenseManager.licensed?(:MSC) == false
  end

  def no_client_license(mac) do
    Mscs.ClientManager.licensed?(:licensed, mac) == true
  end

  def client_login(_ip) do
    # there is no active alarm condition to monitor
    false
  end

end
