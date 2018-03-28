defmodule InfinityOneWeb.API.PublicController do
  use InfinityOneWeb, :controller

  require Logger

  plug(:put_layout, false)

  def server_settings(conn, _params) do
    data = %{
      realm_name: "InfinityOne",
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
      # realm_icon: "https:\/\/secure.gravatar.com\/avatar\/6fa1013f5e7cb449d3d96b36327566da?d=identicon",
      infinityone_version: InfinityOne.version(),
      realm_description: "<p>The coolest place in the universe.<\/p>"
    }

    render(conn, "server_settings.json", data: data)
  end
end
