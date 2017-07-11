defmodule UccChat.NotificationSetting do
  use UccModel, schema: UccChat.Schema.NotificationSetting

  def option_text(options, name) do
    options
    |> Enum.into(%{})
    |> Map.get(name)
  end

  def options(:audio), do: [
    {"none", "None"},
    {"system_default", "Use account preferences (Default)"},
    {"chime", "Chime"},
    {"beep", "Beep"},
    {"chelle", "Chelle"},
    {"ding", "Ding"},
    {"droplet", "Droplet"},
    {"highbell", "Highbell"},
    {"seasons", "Seasons"}
  ]

  def options(field) when field in ~w(desktop mobile)a, do: [
    {"all", "All messages"},
    {"mentions", "Mentions (default)"},
    {"nothing", "Nothing"}
  ]

  def options(:email), do: [
    {"all", "All messages"},
    {"nothing", "Nothing"},
    {"preferences", "Use account preference"}
  ]

  def options(:unread_alert), do: [
    {"on", "On"},
    {"off", "Off"},
    {"preferences", "Use account preference"}
  ]

end
