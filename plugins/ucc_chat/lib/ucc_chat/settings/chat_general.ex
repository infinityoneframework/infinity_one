defmodule UccSettings.Settings.Config.ChatGceneral do

  @all_slash_commands [
    "join", "archive", "kick", "lennyface", "leave", "gimme", "create", "invite",
    "invite-all-to", "invite-all-from", "msg", "part", "unarchive", "tableflip",
    "topic", "mute", "me", "open", "unflip", "shrug", "unmute", "unhide" ]

  @rooms_slash_commands @all_slash_commands

  @chat_slash_commands [
    "lennyface", "gimme", "msg", "tableflip", "mute", "me", "unflip", "shrug", "unmute" ]

  
  use UccSettings.Settings, scope: inspect(__MODULE__), repo: UcxUcc.Repo, schema: [
    [name: "enable_favorite_rooms", type: "boolean", default: "true"],
    [name: "rooms_slash_commands", type: "{:array, :string}", default: inspect(@room_slash_commands)],
    [name: "chat_slash_commands", type: "{:array, :string}", default: inspect(@chat_slash_commands)],
  ]

end
