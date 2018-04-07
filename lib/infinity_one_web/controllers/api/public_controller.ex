defmodule InfinityOneWeb.API.PublicController do
  use InfinityOneWeb, :controller

  alias InfinityOne.Settings.General

  require Logger

  plug(:put_layout, false)

  def server_settings(conn, _params) do
    general = General.get()
    site_avatar_url = General.site_avatar_url(general, external: true)

    data = %{
      realm_name: General.get_site_client_name(general),
      require_email_format_usernames: false,
      push_notifications_enabled: true,
      authentication_methods: %{
        google: false,
        ldap: false,
        password: true,
        email: true,
        remoteuser: false,
        github: false,
        dev: false
      },
      realm_uri: InfinityOneWeb.root_url(),
      email_auth_enabled: true,
      msg: "",
      infinityone_version: InfinityOne.version(),
      realm_description: "<p>The coolest place in the universe.<\/p>"
    }
    |> add_realm_icon(site_avatar_url)

    render(conn, "server_settings.json", data: data)
  end

  defp add_realm_icon(data, nil), do: data

  defp add_realm_icon(data, url), do: Map.put(data, :realm_icon, url)
end
