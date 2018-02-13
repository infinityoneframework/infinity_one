defmodule UccChatWeb.SharedView do
  use UcxUcc.Utils
  use UcxUccWeb.Gettext

  import Phoenix.HTML.Tag, warn: false

  alias UcxUcc.{Permissions, Repo, Accounts, Accounts.User, Hooks}
  alias UccChat.{Subscription, ChatDat}

  require Logger

  def markdown(text), do: text

  def get_all_users do
    Repo.all User
  end

  def get_status(user) do
    UccChat.PresenceAgent.get(user.id)
  end

  def get_room_icon_class(data, status \\ nil)

  def get_room_icon_class(%ChatDat{} = chatd, status) do
    status = status || get_room_status(chatd)
    [
      get_room_icon(chatd),
      "status-" <> status,
      "room-" <> chatd.active_room[:name]
    ]
    |> Enum.join(" ")
  end

  def get_room_icon_class(%{} = room, status) do
    status = status || room[:user_status]
    [
      room[:room_icon],
      "status-" <> status,
      "room-" <> room[:name]
    ]
    |> Enum.join(" ")
  end

  def get_room_icon(chatd), do: chatd.room_map[chatd.channel.id][:room_icon]
  def get_room_status(chatd) do
    # Logger.error "get room status room_map: #{inspect chatd.room_map[chatd.channel.id]}"
    chatd.room_map[chatd.channel.id][:user_status]
  end
  def get_room_display_name(chatd), do: chatd.room_map[chatd.channel.id][:display_name]

  def hidden_on_nil(test, prefix \\ "")
  def hidden_on_nil(_test, ""), do: " hidden"
  def hidden_on_nil(test, prefix) when is_falsy(test), do: " #{prefix}hidden"
  def hidden_on_nil(_, _), do: ""

  def map_field(map, field, default \\ "")
  def map_field(%{} = map, field, default), do: Map.get(map, field, default)
  def map_field(_, _, default), do: default

  def get_ftab_open_class(nil), do: ""
  def get_ftab_open_class(_), do: "opened"

  def get_desktop_notifications_for do
    default = UccChat.NotificationSetting.get_system_name()
    [
      {gettext("Default (%{default}}", default: default), "system_default"},
      {~g(All messages), "all"},
      {~g(Mentions), "mentions"},
      {~g(Nothing), "none"}
    ]
  end

  def get_room_notification_sounds do
    [
      {~g"None", "none"},
      {~g"Use system preferences (Default)", "system_default"},
      {~g"Door (Default)", "door"},
      {~g"Beep", "beep"},
      {~g"Chelle", "chelle"},
      {~g"Ding", "ding"},
      {~g"Droplet", "droplet"},
      {~g"Highbell", "highbell"},
      {~g"Seasons", "seasons"}
    ]
  end
  def get_message_notification_sounds do
    [
      {~g"None", "none"},
      {~g"Use room and system preferences (Default)", "system_default"},
      {~g"Chime (Default)", "chime"},
      {~g"Beep", "beep"},
      {~g"Chelle", "chelle"},
      {~g"Ding", "ding"},
      {~g"Droplet", "droplet"},
      {~g"Highbell", "highbell"},
      {~g"Seasons", "seasons"}
    ]
  end

  @regex1 ~r/^(.*?)(`(.*?)`)(.*?)$/
  @regex2 ~r/\A(```(.*)```)\z/Ums

  def format_quoted_code(string, _, true), do: string
  def format_quoted_code(string, true, _) do
    do_format_multi_line_quoted_code(string)
  end
  def format_quoted_code(string, _, _) do
    do_format_quoted_code(string, "")
  end

  def do_format_quoted_code(string, acc \\ "")
  def do_format_quoted_code("", acc), do: acc
  def do_format_quoted_code(nil, acc), do: acc
  def do_format_quoted_code(string, acc) do
    case Regex.run(@regex1, string) do
      nil -> acc <> string
      [_, head, _, quoted, tail] ->
        acc = acc <> head <> " " <> single_quote_code(quoted)
        do_format_quoted_code(tail, acc)
    end
  end

  def do_format_multi_line_quoted_code(string) do
    case Regex.run(@regex2, string) do
      nil -> string
      [_, _, quoted] ->
        multi_quote_code quoted
    end
  end

  # def multi_quote_code(quoted) do
  #   """
  #   <pre>
  #     <code class='code-colors'>
  #       #{quoted}
  #     </code>
  #   </pre>
  #   """
  # end
  def multi_quote_code(quoted) do
    "<pre><code class='code-colors'>#{quoted}</code></pre>"
  end

  def single_quote_code(quoted) do
    """
    <span class="copyonly">`</span>
    <span>
      <code class="code-colors inline">#{quoted}</code>
    </span>
    <span class="copyonly">`</span>
    """
  end

  def get_avatar_img(username, size \\ "40x40") do
    # Logger.warn "get_avatar #{inspect msg}"
    # ""
    Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{username}.png?set=any&bgset=any&size=#{size}"
  end
  def get_avatar(msg) do
    # Logger.warn "get_avatar #{inspect msg}"
    # ""
    # Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{msg}.png?size=40x40"
    "https://robohash.org/#{msg}.png?set=any&bgset=any&size=40x40"
  end
  def get_large_avatar(username) do
    # Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{username}.png?size=350x310"
    "https://robohash.org/#{username}.png?set=any&bgset=any&size=350x310"
  end

  def has_permission?(user, permission, scope \\ nil), do: Permissions.has_permission?(user, permission, scope)
  def has_role?(user, role, scope), do: Accounts.has_role?(user, role, scope)
  def has_role?(user, role), do: Accounts.has_role?(user, role)

  def user_muted?(%{} = user, channel_id), do: UccChat.Channel.user_muted?(user.id, channel_id)

  def content_home_title do
    "test"
  end

  def content_home_body do
    "test"
  end

  def subscribed?(user_id, channel_id) do
    Subscription.subscribed?(channel_id, user_id)
  end

  def avatar_url(%{avatar_url: nil, username: username}), do: avatar_url(username)
  def avatar_url(%{avatar_url: avatar_url}), do: avatar_url
  def avatar_url(username) do
    UccChat.AvatarService.avatar_url username
  end

  def user_details_thead_hook do
    Hooks.user_details_thead_hook []
  end

  def user_details_body_hook(user) do
    Hooks.user_details_body_hook [], user
  end

  def user_card_details(user) do
    Hooks.user_card_details [], user
  end

  def user_list_item_hook(user) do
    Hooks.user_list_item_hook [], user
  end

  def messages_header_icons(chatd) do
    content_tag :span, [class: "messages-header-icons"] do
      Hooks.messages_header_icons [], chatd
    end
  end

  def account_box_header(user) do
    Hooks.account_box_header([], user)
  end

  def nav_option_buttons do
    Hooks.nav_option_buttons []
  end

  def format_errors(changeset, opts \\ [])
  def format_errors(changeset, opts) when is_list(opts) do
    separator = opts[:separator] || ": "
    formatter = opts[:formatter] || &default_error_formatter/2
    format_errors(changeset, formatter, separator)
  end

  def format_errors(changeset, separator) when is_binary(separator) do
    format_errors(changeset, &default_error_formatter/2, separator)
  end

  def format_errors(changeset, formatter) when is_function(formatter) do
    format_errors(changeset, formatter, ": ")
  end

  def format_errors(%Ecto.Changeset{errors: errors}, formatter, separator) do
    errors
    |> Enum.map(fn {field, {error, _}} -> {to_string(field), error} end)
    |> formatter.(separator)
  end

  def format_errors(term, _, _), do: to_string(term)

  def default_error_formatter(list, sep) do
    list
    |> Enum.map(fn {a, b} -> [a, sep, b] end)
    |> Enum.join("\n")
  end

  def size_string_kb(size, rnd \\ 2)

  def size_string_kb(size, rnd) when size < 1024 do
    float_to_string(size, rnd) <> "KB"
  end

  def size_string_kb(size, rnd) when size < 1024 * 1024 do
    float_to_string(size / 1024, rnd) <> "MB"
  end

  def size_string_kb(size, rnd) when size < 1024 * 1024 * 1024 do
    float_to_string(size / 1024 / 1024, rnd) <> "GB"
  end

  def size_string_kb(size, rnd) when size < 1024 * 1024 * 1024 * 1024 do
    float_to_string(size / 1024 / 1024 / 1024, rnd) <> "TB"
  end

  def size_string_kb(size, rnd) when size < 1024 * 1024 * 1024 * 1024 * 1024 do
    float_to_string(size / 1024 / 1024 / 1024 / 1024, rnd) <> "PB"
  end

  def size_string_kb(size, rnd) do
    float_to_string(size / 1024 / 1024 / 1024 / 1024 / 1024 / 1024, rnd) <> "EB"
  end

  # def float_to_string(size, rnd)

  def float_to_string(size, rnd) when is_float(size) do
    size |> Float.round(rnd) |> to_string
  end

  def float_to_string(size, _rnd) do
    to_string size
  end

  def get_available_capacity(settings) do
    case UccChat.Settings.FileUpload.get_disk_usage(settings) do
      {:ok, %{available: available}} -> size_string_kb(available)
      _ -> ~g(error)
    end
  end

  def get_uploads_size(settings) do
    case UccChat.Settings.FileUpload.get_uploads_size(settings) do
      {:ok, size} -> size_string_kb(size)
      _ -> ~g(error)
    end
  end

  def get_uploads_used_percent(settings) do
    case UccChat.Settings.FileUpload.get_disk_usage(settings) do
      {:ok, %{percent: percent}} ->
        percent |> Float.round(1) |> to_string() |> Kernel.<>("%")
      _ -> ~g(error)
    end
  end

  defmacro gt(text, opts \\ []) do
    quote do
      gettext(unquote(text), unquote(opts))
    end
  end
end
