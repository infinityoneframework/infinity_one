defmodule UccChat.NotificationSetting do
  use UccModel, schema: UccChat.Schema.NotificationSetting

  use UcxUccWeb.Gettext

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

  def options(:audio_mode), do: [
    {"default", gettext("Default (%{default})", default: "Mentions")},
    {"all", ~g(All messages)},
    {"mentions", ~g(Mentions)}
  ]


  def options(field) when field in ~w(desktop mobile)a, do: [
    {"all", ~g"All messages"},
    {"mentions", ~g"Mentions (default)"},
    {"nothing", ~g"Nothing"}
  ]

  def options(:email), do: [
    {"all", ~g"All messages"},
    {"nothing", ~g"Nothing"},
    {"preferences", ~g"Use account preference"}
  ]

  def options(:unread_alert), do: [
    {"on", ~g"On"},
    {"off", ~g"Off"},
    {"preferences", ~g"Use account preference"}
  ]

end
