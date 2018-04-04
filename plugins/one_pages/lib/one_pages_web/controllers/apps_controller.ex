defmodule OnePagesWeb.AppsController do
  use OnePagesWeb, :controller

  alias OnePages.Github.Server
  alias OnePages.Version

  require Logger

  def index(conn, _params) do
    # {templ, bindings} =
    bindings =
      case Server.get() do
        {:ok, version} ->
          get_download_url(conn, version)
        {:error, _timeout} ->
          get_download_url(conn, Server.get_last())
      end
    render conn, "show.html", bindings
  end

  def show(conn, %{"id" => platform}) do
    platform = String.to_existing_atom(platform)
    bindings =
      case Server.get() do
        {:ok, version} ->
          get_download_url(platform, version)
        {:error, _timeout} ->
          get_download_url(conn, Server.get_last())
      end
    render conn, "show.html", bindings
  end

  defp get_download_link(:mac, version), do: Version.get_mac_download_link(version)
  defp get_download_link(:win, version), do: Version.get_win_download_link(version)
  defp get_download_link(:linux, version), do: Version.get_linux_download_link(version)
  defp get_download_link(platform, _version) when is_atom(platform), do: nil

  defp get_download_url(_conn, nil) do
    {"index.html", []}
  end

  defp get_download_url(platform, version) when is_atom(platform) do
    [{:url, get_download_link(platform, version)} | platform_bindings(platform)]
  end

  defp get_download_url(conn, version) do
    conn
    |> match_user_agent
    |> get_download_url(version)
  end

  defp platform_bindings(:mac) do
    [
      platform_name: "macOS",
      help_url: "/help/desktop-app-install-guide#installing-on-macos",
      image: "/images/landing-page/macbook.png"
    ]
  end

  defp platform_bindings(:win) do
    [
      platform_name: "Windows",
      help_url: "/help/desktop-app-install-guide#installing-on-windows",
      image: "/images/landing-page/microsoft.png"
    ]
  end

  defp platform_bindings(:linux) do
    [
      platform_name: "Linux",
      help_url: "/help/desktop-app-install-guide#installing-on-linux",
      image: "/images/landing-page/ubuntu.png"
    ]
  end

  defp platform_bindings(platform) do
    Logger.warn "unknown platform: " <> inspect(platform)
    []
  end

  defp match_user_agent(%{req_headers: headers}) do
    agent =
      case List.keyfind(headers, "user-agent", 0) do
        {_, agent} -> agent
        _ -> ""
      end
    cond do
      agent =~ ~r/Android/ -> :unsupported
      agent =~ ~r/iPhone/ -> :unsupported
      agent =~ ~r/iPad/ -> :unsupported
      agent =~ ~r/Macintosh/ -> :mac
      agent =~ ~r/Windows/ -> :win
      agent =~ ~r/Linux/ -> :linux
      true -> :unknown
    end
  end
end
