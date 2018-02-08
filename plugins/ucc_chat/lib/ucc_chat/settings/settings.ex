defmodule UccChat.Settings do
  @moduledoc """
  The overall application settings the UccChat Plug In.

  With the use of `UccSettiongs`, this module provides accessors and
  setters for each of the Setting sub modules.

  In addition, several help functions are provided for transforming
  the data.

  TODO: I don't believe some of there helpers belong here. Perhaps the
        should live in their own domain modules. We may want to move them
        in the future.
  """

  use UccSettings

  alias UccChat.Notification

  def get_desktop_notification_duration(user, channel) do
    cond do
      not enable_desktop_notifications() ->
        nil
      not user.account.enable_desktop_notifications ->
        nil
      not is_nil(user.account.desktop_notification_duration) ->
        user.account.desktop_notification_duration
      true ->
        case Notification.get_notification(user.account.id, channel.id) do
          nil ->
            desktop_notification_duration()
          %{settings: %{duration: nil}} ->
            desktop_notification_duration()
          %{settings: %{duration: duration}} ->
            duration
        end
    end
  end

  def notifications_settings(%{} = user, %{id: channel_id}) do
    notifications_settings(user, channel_id)
  end

  def notifications_settings(%{account: account}, channel_id) do
    with true <- enable_desktop_notifications(),
         true <- account.enable_desktop_notifications do
      account
      |> Notification.get_notification(channel_id)
      |> Map.get(:settings, %{})
    end
  end

  def desktop_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{desktop: mode} -> mode
      other -> other
    end
  end

  def desktop_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{desktop: mode} -> mode
      other -> other
    end
  end

  def email_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{email: mode} -> mode
      other -> other
    end
  end

  def mobile_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{mobile: mode} -> mode
      other -> other
    end
  end

  def unread_alert_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{unread_alert: mode} -> mode
      other -> other
    end
  end

  @doc """
  Get the configured alert audio file name if applicable.

  Basically, a large state table that looks at the message type in the
  following 2 categories:

  * Mention or direct message
  * Regular public of private room message

  Based on the various settings either a sound file name or nil will
  is returned. A nil indicating that a sound alert should not be played.

  Settings are taken from 3 sources:

  * The global settings from the ChatGeneral Administration page.
  * The user's account settings.
  * The user's notification settings from the Notifications FlexTab.

  The logic for choosing whether a sound should be played, and which
  sound is coded by pattern matching on 6 different attributes.
  """
  def get_new_message_sound(user, channel_id, mention \\ true) do
    # channel = UccChat.Channel.get channel_id
    # IO.inspect {user.username, channel.name, channel.id}
    chat_general = UccChat.Settings.ChatGeneral.get
    system_audio = chat_general.default_message_notification_audio

    {audio, audio_mode} =
      if notifications_settings = notifications_settings(user, channel_id) do
        {notifications_settings.audio, notifications_settings.audio_mode}
      else
        {"system_default", "default"}
      end

    opts = %{
      mention: mention,
      default: get_system_new_message_sound(),
      account: user.account.new_message_notification,
      system: chat_general.audio_notifications_default_alert,
      audio: audio,
      audio_mode: audio_mode,
    }

    case opts do
      %{audio: "none"} -> nil
      %{audio: "system_default", account: "none"} -> nil
      %{audio_mode: "default", account: "system_default", system: "none"} -> nil
      %{audio_mode: "default", account: "none"} -> nil
      %{mention: true, audio_mode: "default", account: "system_default"} -> system_audio
      %{mention: true, audio_mode: "default", account: sound} -> sound
      %{mention: true, audio_mode: "default", audio: "system_default"} -> system_audio
      %{mention: true, audio_mode: "default", audio: sound} -> sound
      %{mention: true, audio: "system_default", account: "system_default"} -> system_audio
      %{mention: true, audio: "system_default", account: sound} -> sound
      %{mention: true, audio: "system_default"} -> system_audio
      %{mention: true, audio: sound} -> sound
      # just in case we missed something
      %{mention: true} -> nil
      %{audio_mode: "default", audio: "system_default", system: "all"} -> system_audio
      %{audio_mode: "default", audio: sound, system: "all"} -> sound
      %{audio_mode: "all", account: "system_default", audio: "system_default"} -> system_audio
      %{audio_mode: "all", account: "none", audio: "system_default"} ->  nil
      %{audio_mode: "all", account: sound, audio: "system_default"} ->  sound
      %{audio_mode: "all", audio: sound} -> sound
      _ -> nil
    end

    # # A version with instrumentation for debugging. TODO: Remove this before merging.
    # case opts do
    #   %{audio: "none"} -> nil |> print(1)
    #   %{audio: "system_default", account: "none"} -> nil |> print(2)
    #   %{audio_mode: "default", account: "system_default", system: "none"} -> nil |> print(3)
    #   %{audio_mode: "default", account: "none"} -> nil |> print(4)
    #   %{mention: true, audio_mode: "default", account: "system_default"} -> system_audio |> print(5)
    #   %{mention: true, audio_mode: "default", account: sound} -> sound |> print(5.5)
    #   %{mention: true, audio_mode: "default", audio: "system_default"} -> system_audio |> print(6)
    #   %{mention: true, audio_mode: "default", audio: sound} -> sound |> print(7)
    #   %{mention: true, audio: "system_default", account: "system_default"} -> system_audio |> print(8)
    #   %{mention: true, audio: "system_default", account: sound} -> sound |> print(9)
    #   %{mention: true, audio: "system_default"} -> system_audio |> print(10)
    #   %{mention: true, audio: sound} -> sound |> print(11)
    #   %{mention: true} -> nil |> print(12) # just in case we missed something
    #   %{audio_mode: "default", audio: "system_default", system: "all"} ->  system_audio |> print(13)
    #   %{audio_mode: "default", audio: sound, system: "all"} -> sound |> print(14)
    #   # %{audio_mode: "default", audio: "system_default"} ->  nil  # this should be caught by default case
    #   %{audio_mode: "all", account: "system_default", audio: "system_default"} ->  system_audio |> print(15)
    #   %{audio_mode: "all", account: "none", audio: "system_default"} ->  nil |> print(16)
    #   %{audio_mode: "all", account: sound, audio: "system_default"} ->  sound |> print(17)
    #   %{audio_mode: "all", audio: sound} -> sound |> print(18)
    #   _ -> nil |> print(16)
    # end
    # |> print(:result)

  end

  # defp print(value, label) do
  #   IO.inspect value, label: to_string(label)
  # end

  def get_system_new_message_sound,
    do: UccChat.Settings.default_message_notification_audio()

  def get_system_new_room_sound, do: "door"

  def get_system_message_sound, do: "none"

end
