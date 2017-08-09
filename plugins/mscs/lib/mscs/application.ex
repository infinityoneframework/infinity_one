defmodule Mscs.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  def children do
    import Supervisor.Spec

    [
      supervisor(Mscs.ClientsSupervisor, []),
      worker(Mscs.SystemAgent, []),
      worker(Mscs.ClientAgent, []),
      worker(Mscs.ClientContextManager, []),
      worker(Ucx.LicenseManager, [[:MSC]]),
      worker(Mscs.AlarmManager, []),
    ]
  end
end
