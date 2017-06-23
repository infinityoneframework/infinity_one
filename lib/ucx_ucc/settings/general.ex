defmodule UccSettings.Settings.Config.General do

  use UccSettings.Settings, scope: inspect(__MODULE__), repo: UcxUcc.Repo, schema: [
      [name: "site_url", type: "string", default: "http://change-this"],
      [name: "site_name", type: "string", default: "UccChat"],
      [name: "enable_desktop_notifications", type: "boolean", default: "true"],
      [name: "desktop_notification_duration", type: "integer", default: "5"],
    ]
end

