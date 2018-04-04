defmodule OnePages.Application do

  def children do
    import Supervisor.Spec

    [
      worker(OnePages.Github.Server, [])
    ]
  end

  # def start(_type, _args) do
  # end
end
