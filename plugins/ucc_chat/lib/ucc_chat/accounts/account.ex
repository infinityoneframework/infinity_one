defmodule UccChat.Accounts.Account do
  use Unbrella.Plugin.Schema, UcxUcc.Accounts.Account

  import Ecto.Query

  alias UcxUcc.Accounts.{User, Account}
  alias UccChat.Schema.{Notification, AccountNotification}

  extend_schema UcxUcc.Accounts.Account do
    field :language, :string, default: "en"
    field :desktop_notification_enabled, :boolean, default: true
    field :desktop_notification_duration, :integer
    field :unread_alert, :boolean, default: true
    field :use_emojis, :boolean, default: true
    field :convert_ascii_emoji, :boolean, default: true
    field :auto_image_load, :boolean, default: true
    field :save_mobile_bandwidth, :boolean, default: true
    field :collapse_media_by_default, :boolean, default: false
    field :unread_rooms_mode, :boolean, default: false
    field :hide_user_names, :boolean, default: false
    field :hide_flex_tab, :boolean, default: false
    field :hide_avatars, :boolean, default: false
    field :merge_channels, :boolean, default: nil
    field :enter_key_behaviour, :string, default: "normal"
    field :view_mode, :integer, default: 1
    field :email_notification_mode, :string, default: "all"
    field :highlights, :string, default: ""
    field :enable_desktop_notifications, :boolean, default: true
    field :new_room_notification, :string, default: "system_default"
    field :new_message_notification, :string, default: "system_default"
    field :chat_mode, :boolean, default: false
    field :emoji_category, :string, default: "people"
    field :emoji_tone, :integer, default: 0
    field :emoji_recent, :string, default: ""
    field :status_message, :string, default: ""
    field :status_message_history, :string, default: ""

    many_to_many :notifications, Notification, join_through: AccountNotification, on_delete: :delete_all
  end

  @fields [:language, :desktop_notification_enabled, :desktop_notification_duration] ++
          [:unread_alert, :use_emojis, :convert_ascii_emoji, :auto_image_load] ++
          [:save_mobile_bandwidth, :collapse_media_by_default, :unread_rooms_mode] ++
          [:hide_user_names, :hide_flex_tab, :hide_avatars, :merge_channels, :view_mode] ++
          [:email_notification_mode, :highlights, :new_room_notification] ++
          [:new_message_notification, :chat_mode, :enable_desktop_notifications] ++
          [:emoji_category, :emoji_tone, :emoji_recent, :status_message, :status_message_history]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, @fields)
    |> validate_required([])
  end

  def get(user_id) do
    from u in User,
      join: a in Account,
      on: a.user_id == u.id,
      where: u.id == ^user_id,
      select: a
  end

end
