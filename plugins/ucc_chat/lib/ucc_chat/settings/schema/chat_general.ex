defmodule UccChat.Settings.Schema.ChatGeneral do
  use UccSettings.Settings.Schema

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
  end

  @fields [
    :enable_favorite_rooms, :rooms_slash_commands, :chat_slash_commands,
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

end
