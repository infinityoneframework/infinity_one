defmodule OneChat.NotificationSetting do
  use OneModel, schema: OneChat.Schema.NotificationSetting

  use InfinityOneWeb.Gettext

  alias OneChatWeb.Admin.Page.ChatGeneral

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
    {"default", gettext("Default (%{default})", default: get_system_audio_name())},
    {"all", ~g(All messages)},
    {"mentions", ~g(Mentions)}
  ]

  def options(field) when field in ~w(desktop mobile)a, do: [
    {"default", gettext("Default (%{default})", default: get_system_name())},
    {"all", ~g"All messages"},
    {"mentions", ~g"Mentions"},
    {"none", ~g"Nothing"}
  ]

  def options(:email), do: [
    {"all", ~g"All messages"},
    {"none", ~g"Nothing"},
    {"preferences", ~g"Use account preference"}
  ]

  def options(:unread_alert), do: [
    {"on", ~g"On"},
    {"off", ~g"Off"},
    {"preferences", ~g"Use account preference"}
  ]

  def get_system_name() do
    ChatGeneral.lookup_option(:notifications,
      OneSettings.desktop_notifications_default_alert)
  end

  def get_system_audio_name() do
    ChatGeneral.lookup_option(:notifications,
      OneSettings.audio_notifications_default_alert)
  end
end
