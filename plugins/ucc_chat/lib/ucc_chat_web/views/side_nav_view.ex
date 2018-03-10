defmodule UccChatWeb.SideNavView do
  use UccChatWeb, :view

  alias UcxUcc.Hooks
  alias UcxUcc.Accounts.Account

  require Logger
  # import UccChat.AvatarService, only: [avatar_url: 1]
  def chat_room_item_li_class(item) do
    acc = "link-room-#{item[:name]} background-transparent-darker-hover"
    with acc <- if(item[:open], do: acc <> " active", else: acc),
         acc <- if(item[:has_unread], do: acc <> " has-unread has-alert", else: acc),
         do: if(item[:alert], do: acc <> " has-alert", else: acc)
  end

  def is_active(items) do
    if Enum.reduce(items, false, &(&2 || &1[:is_active])), do: " active", else: ""
  end

  def get_registered_menus(%User{}), do: []

  def get_user_status(%User{} = user) do
    "status-" <> get_visual_status(user)
  end

  def get_visual_status(%User{} = user) do
    user.chat_status
  end

  def get_user_avatar(%User{}) do
    ""
  end

  def get_user_name(%User{} = user), do: user.username

  def show_admin_option(%User{} = user) do
    user = Repo.preload(user, [:roles, user_roles: :role])
    UccAdmin.has_admin_permission?(user)
  end

  def username(chatd), do: chatd.user.username

  def account_box_class() do
    Hooks.account_box_class []
  end

  def nav_room_item_icons(room) do
    Hooks.nav_room_item_icons [], room
  end

  def user_status_message(%Account{status_message: ""}), do: nil
  def user_status_message(%Account{status_message: message}), do: message

  def user_status_message(room) do
    if room.channel_type == 2 and room.user.account.status_message do
      room.user.account.status_message
    end
  end

  def status_message_list(account) do
    list =
      account
      |> UccChat.Accounts.get_status_message_history
      |> Enum.map(& {&1, &1})

    [{"➖ " <> ~g"(No Message)", "__clear__"}, {"➕ " <> ~g"(Enter new Message)", "__new__"},
     {"✏  " <> ~g"(Edit History)", "__edit__"} | list]
  end

  def status_message_edit(account) do
    account
    |> UccChat.Accounts.get_status_message_history
    |> Enum.reject(& &1 == "")
  end
end

