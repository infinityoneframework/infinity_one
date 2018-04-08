defmodule OneChat.Settings.Schema.ChatGeneral do
  @moduledoc """
  The Schema for the ChatGeneral Settings module.

  ## Message replacement patterns

  The `:message_replacement_patterns` field has very special handling here:

  * Input fields come in on the virtual `:patterns` field.
  * The `:patterns` map is converted to a binary and put in the
    `:message_replacement_patterns` field
  * This binary contains an elixir array that is later dynamically evaluated.
  * A dynamic module is then recompiled by `OneChat.MessageReplacementPatterns.compile/0`
    after a brief spawned sleep.

  ### Example patterns

      "[{\"Jira\",\"\\\\[(UCX-[0-9]+)\\\\]([^\\\\(]|$|\\\\n)\",\"[\\\\1](https://emetrotel.atlassian.net/browse/\\\\1)\\\\2\",\"\"},{\"User Status\",\"@@([\\\\w\d0-9_]+)\",\"<i class='icon-at status-offline' data-status-name='\\\\1'></i>\\\\1\",\"Elixir.OneChat.refresh_users_status\"},{\"Status & Message\",\"@@@([\\\\w0-9_]+)\",\"<i class='icon-at status-offline' data-status-name='\\\\1'></i>\\\\1<span class='status-message color-primary-action-color' data-username='\\\\1'></span>\",\"Elixir.OneChat.refresh_users_status\"},]"

  """
  use OneSettings.Settings.Schema
  use InfinityOneWeb.Gettext

  require Logger

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
    field :message_replacement_patterns, :string, default: ""
    field :patterns,  :map, default: %{}, virtual: true
  end

  @required_fields [
    :enable_favorite_rooms, :rooms_slash_commands, :chat_slash_commands,
    :unread_count, :unread_count_dm, :default_message_notification_audio,
    :audio_notifications_default_alert, :desktop_notifications_default_alert,
    :mobile_notifications_default_alert, :max_members_disable_notifications
  ]

  @fields [:patterns, :message_replacement_patterns, :first_channel_after_login | @required_fields]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> first_channel_after_login(params)
    |> message_replacement_patterns()
    |> validate_required(@required_fields)
    |> prepare_changes(&prepare_patterns/1)
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

      if first_channel_after_login == "" || first_channel_after_login =~ OneChat.Schema.Channel.validate_name_re() do
        put_change changeset, :first_channel_after_login, first_channel_after_login
      else
        add_error changeset, :first_channel_after_login, ~g(Invalid format)
      end
    else
      changeset
    end
  end

  defp message_replacement_patterns(%{changes: %{patterns: patterns}} = changeset) do
    {changeset, string} =
      patterns
      |> Map.values()
      |> Enum.with_index()
      |> Enum.reduce({changeset, ""}, fn
        {%{"deleted" => "true"}, _}, acc ->
          acc
        {map, index}, {changeset, acc} ->
          changeset =
            changeset
            |> validate_re(map["re"], index)
            |> validate_name(map["name"], index)
            |> validate_command(map["cmd"], index)
          if changeset.valid? do
            re = String.replace(map["re"], "\\", "\\\\")
            sub = String.replace(map["sub"], "\\", "\\\\")
            {changeset, acc <> ~s/{"#{map["name"]}","#{re}","#{sub}","#{map["cmd"] || ""}"},/}
          else
            {changeset, acc}
          end
      end)
    new_value = "[#{string}]"
    if changeset.valid? and changeset.data.message_replacement_patterns != new_value do
      put_change changeset, :message_replacement_patterns, new_value
    else
      changeset
    end
  end

  defp message_replacement_patterns(changeset) do
    # Logger.warn "changeset: " <> inspect(changeset)
    changeset
  end

  defp validate_re(changeset, re, index) do
    case Regex.compile(re) do
      {:ok, _} ->
        changeset
      {:error, error} ->
        error =
          error
          |> inspect()
          |> String.replace(~r/['\{\}]/, "")
        add_error(changeset, pattern_field_name(:re, index), error)
    end
  end

  defp validate_command(changeset, command, index) do
    if is_nil(command) or command =~ ~r/(^[A-Z][\w\.]+\.[a-z_]+$)|(^$)/ do
      changeset
    else
      add_error(changeset, pattern_field_name(:cmd, index), ~g(invalid format))
    end
  end

  defp validate_name(changeset, name, index) do
    if is_nil(name) or name == "" do
      add_error(changeset, pattern_field_name(:name, index), ~g(is required))
    else
      changeset
    end
  end

  defp pattern_field_name(field, index), do: "chat_general[patterns[#{index}]#{field}]"

  defp prepare_patterns(%{action: action} = changeset) when action in ~w(insert update)a do
    spawn fn ->
      Process.sleep(250)
      OneChat.MessageReplacementPatterns.compile()
    end
    changeset
  end

  defp prepare_patterns(changeset) do
    changeset
  end
end
