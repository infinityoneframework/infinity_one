defmodule UccChatWeb.MasterView do
  use UccChatWeb, :view
  alias UccChat.{ChannelService, ChatDat}
  alias UccChat.Schema.Channel, as: ChannelSchema
  # alias UccChatWeb.MessageView
  # alias UccUiFlexTabWeb.TabBarView
  alias UccChatWeb.{SharedView, MessageView}
  alias UccUiFlexTabWeb.TabBarView

  require IEx

  def get_pagination(info) do
    attrs =
      ~w(page_number page_size total_entries total_pages)a
      |> Enum.reduce([class: "pagination", style: "display: none;"], fn key, acc ->
        if val = info[:page][key] do
          Keyword.put(acc, String.to_atom("data-#{key}"), val)
        else
          acc
        end
      end)
    content_tag :div, attrs, do: []
  end
  def get_admin_class(_user), do: ""
  def get_window_id(channel), do: "chat-window-#{channel.id}"

  def embedded_version, do: false
  def unread, do: false

  def show_toggle_favorite(chatd) do
    SharedView.subscribed? chatd.user.id, chatd.channel.id
  end

  def get_user_status(_), do: "offline"

  def container_bars_show(_channel) do
    # %div(class="container-bars #{container_bars_show unreadData uploading}}">
    "show"
  end
  # def get_unread_data(_), do: false
  def get_unread_data(_) do
    count_span = content_tag :span, class: "unread-cnt" do
      "0"
    end
    %{
      count: " new messages",
      since: " new messages since 11:08 AM",
      count_span: count_span
    }
    # %{count: "78 new messages", since: "78 new messages since 11:08 AM"}
  end

  def get_uploading(_conn), do: []
  def has_upload_error(_conn) do
    # "error-background error-border"
    ""
  end
  def get_upload_error(_conn) do
    false
  end
  def get_error_percentage(_error), do: 100
  def get_error_name(_error), do: ""
  def message_box_selectable do
    # "selectable"
    ""
  end
  def view_mode(user) do
    case user.account.view_mode do
      1 -> ""
      2 -> " cozy"
      3 -> " compact"
      _ -> ""
    end
  end

  def has_more_next(true), do: " has-more-next"
  def has_more_next(_), do: ""

  def has_more(), do: false
  def can_preview, do: true

  def hide_avatar(user) do
    if user.account.hide_avatars, do: " hide-avatars", else: ""
  end
  def hide_username(user) do
    if user.account.hide_user_names, do: " hide-usernames", else: ""
  end

  def is_loading, do: false
  def get_loading, do: ""
  def has_more_next, do: false

  def loading, do: ""
  def get_mb(chatd), do: UccChatWeb.MessageView.get_mb(chatd)

  def get_open_ftab(nil, _), do: nil
  def get_open_ftab({title, _}, flex_tabs) do
    Enum.find(flex_tabs, fn tab ->
      tab[:open] && tab[:title] == title
    end)
  end

  def cc(config, item) do
    if apply UccSettings, item, [config] do
      ""
    else
      " hidden"
    end
  end

  def uu(true, "User Info"), do: ""
  def uu(false, "Members List"), do: ""
  def uu(_, _), do: " hidden"

  def get_fav_icon(chatd) do
    case ChatDat.get_channel_data(chatd) do
      %{type: :starred} -> "icon-star-empty"
      _ -> "icon-star-empty"
    end
  end

  def get_fav_icon_label(chatd) do
    case ChatDat.get_channel_data(chatd) do
      %{type: :starred} ->
        {"icon-star favorite-room pending-color", "Unfavorite"}
      _other ->
        {"icon-star-empty", "Favorite"}
    end
  end

  def favorite_room?(chatd) do
    ChatDat.get_channel_data(chatd)[:type] == :starred
  end

  def favorite_room?(%User{} = user, %ChannelSchema{} = channel) do
    ChannelService.favorite_room?(user, channel)
  end

  def direct?(chatd) do
    chatd.channel.type == 2
  end

  def get_chat_settings(channel) do
    """
    window.chat_settings = {
      link_preview: false,
      use_emojis: true,
      allow_upload: #{UccChat.AttachmentService.allowed?(channel)},
      accepted_media_types: '#{UccSettings.accepted_media_types()}',
      maximum_file_upload_size_kb: #{UccSettings.maximum_file_upload_size_kb()},
      protect_upload_files: #{UccSettings.protect_upload_files()},
    };
    UccChat.settings = chat_settings;
    """
  end

  def status_message(chatd, name) do
    chatd.room_map
    |> Map.values
    |> Enum.find(& &1.display_name == name)
    |> case do
      %{status_message: message} -> message
      _ -> ""
    end
  end

end
