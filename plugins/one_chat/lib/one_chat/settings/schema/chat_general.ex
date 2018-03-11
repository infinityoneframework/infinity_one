defmodule OneChat.Settings.Schema.ChatGeneral do
  use OneSettings.Settings.Schema

  @all_slash_commands [
    "join", "archive", "kick", "lennyface", "leave", "gimme", "create", "invite",
    "invite-all-to", "invite-all-from", "msg", "part", "unarchive", "tableflip",
    "topic", "mute", "me", "open", "unflip", "shrug", "unmute", "unhide" ] |>
    Enum.join("\n")

  @rooms_slash_commands @all_slash_commands

  @chat_slash_commands [
    "lennyface", "gimme", "msg", "tableflip", "mute", "me", "unflip",
    "shrug", "unmute" ] |> Enum.join("\n")


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_chat_general" do
    field :enable_favorite_rooms, :boolean, default: true
    field :rooms_slash_commands, :string, default: @rooms_slash_commands
    field :chat_slash_commands, :string, default: @chat_slash_commands
    field :unread_count, :string, default: "user_and_group"
    field :unread_count_dm, :string, default: "all"
    field :default_message_notification_audio, :string, default: "chime"
    field :audio_notifications_default_alert, :string, default: "mentions"
    field :desktop_notifications_default_alert, :string, default: "mentions"
    field :mobile_notifications_default_alert, :string, default: "mentions"
    field :max_members_disable_notifications, :integer, default: 100
    field :first_channel_after_login, :string, default: ""
  end

  @fields [
    :enable_favorite_rooms, :rooms_slash_commands, :chat_slash_commands,
    :unread_count, :unread_count_dm, :default_message_notification_audio,
    :audio_notifications_default_alert, :desktop_notifications_default_alert,
    :mobile_notifications_default_alert, :max_members_disable_notifications,
    :first_channel_after_login,
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> first_channel_after_login(params)
    |> validate_required(@fields -- [:first_channel_after_login])
  end

  @doc """
  Changeset pipeline helper to handle clearing the text field since Phoenix
  strips out the empty string.

  Look for the absence of the field in params when there is already a
  non empty string set and add "" to the changes. However, we only do this
  if the field is not present in the changes or params.

  Note: There is probably a build in way to do this, but I'm not aware
        of it. If someone knows a better way, please submit a PR.
  """
  def first_channel_after_login(changeset, params) do
    first_channel_after_login = params["first_channel_after_login"] || ""
    if params != %{} and not :first_channel_after_login in Map.keys(changeset.changes) and
      first_channel_after_login != changeset.data.first_channel_after_login do
      put_change changeset, :first_channel_after_login, first_channel_after_login
    else
      changeset
    end
  end

end
