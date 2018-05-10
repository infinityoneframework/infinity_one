defmodule OneSettings.Application do
  @env Mix.env

  def start(_, _) do
    env = @env
    unless env == :test do
      spawn fn ->
        Process.sleep(1_500)
        load_settings()
      end
    end
  end

  defp load_settings do
    :infinity_one
    |> Application.get_env(:settings_modules, [])
    |> Enum.each(fn mod ->
      if mod.get() in [nil, %{}] do
        mod.init();
      end
    end)
  end
end
