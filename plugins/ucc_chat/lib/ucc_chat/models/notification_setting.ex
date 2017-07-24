defmodule UccChat.NotificationSetting do
  use UccModel, schema: UccChat.Schema.NotificationSetting

  @audio_options [
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

  @audio_options_select Enum.map(@audio_options, &{elem(&1, 1), elem(&1, 0)})

  def option_text(options, name) do
    options
    |> Enum.into(%{})
    |> Map.get(name)
  end

  def options_select(:audio), do: @audio_options_select

  def options(:audio),        do: @audio_options

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
