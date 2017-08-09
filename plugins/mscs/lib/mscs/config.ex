defmodule Mscs.Config do
  require Logger

  alias UcxUccWeb.Endpoint

  @env Mix.env

  @filenames [
    stunaddr: "/etc/asterisk/rtp_additional.conf",
    ucxport: "/etc/asterisk/ucx_general_additional.conf",
    port: "/etc/httpd/conf.d/mscs.conf",
  ]

  def set_outside_config!(:port) when @env == :dev, do: nil
  def set_outside_config!(item) do
    config_filename(item)
    |> File.read
    |> find_config_item(item)
    |> save_config_item(item)
    log_config_item(item)
  end

  # try config first or use hard coded values. This allows us to test
  defp config_filename(item) do
    Application.get_env(:mscs, :config_filename, [])
    |> Keyword.get(item, Keyword.get(@filenames, item))
  end

  defp find_config_item({:ok, file}, :ucxport) do
    case Regex.run ~r/port=([\d]+)/, file do
      [_, port] -> port
      _ -> nil
    end
  end
  defp find_config_item({:ok, file}, :port) do
    case Regex.run ~r/HTTP_HOST\}:([\d]+)/, file do
      [_, port] -> port
      _ -> nil
    end
  end
  defp find_config_item({:ok, file}, :stunaddr) do
    case Regex.run ~r/stunaddr=(.+)/, file do
      [_, addr] -> addr
      _ -> nil
    end
  end
  defp find_config_item(_, _), do: nil

  defp save_config_item(nil, _), do: nil
  defp save_config_item(port, :ucxport),
    do: Application.put_env(:mscs, :ucxport, String.to_integer(port))
  defp save_config_item(port, :port) do
    ep = Application.get_env(:mscs, Endpoint)
    |> put_in([:https, :port], String.to_integer(port))
    Application.put_env(:mscs, Endpoint, ep)
  end
  defp save_config_item(addr, :stunaddr) do
    unless Application.get_env(:mscs, :stunaddr),
      do: Application.put_env(:mscs, :stunaddr, String.strip(addr))
  end

  def log_config_item(:ucxport) do
    port = Application.get_env :mscs, :ucxport
    Logger.info "Using UCXPORT: #{port}"
  end
  def log_config_item(:port) do
    port = Application.get_env(:mscs, Endpoint)
    |> get_in([:https, :port])
    Logger.info "Using HTTPS PORT: #{port}"
  end
  def log_config_item(:stunaddr) do
    addr = Application.get_env :mscs, :stunaddr
    Logger.info "Using STUNADDR: #{addr}"
  end
  def log_config_item(_), do: nil

end
