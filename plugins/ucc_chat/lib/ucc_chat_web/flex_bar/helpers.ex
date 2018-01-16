defmodule UccChatWeb.FlexBar.Helpers do

  use UcxUccWeb.Gettext

  defmacro __using__(_) do
    quote do
      use UccUiFlexTabWeb.FlexBar.Helpers

      import unquote(__MODULE__)

      alias UccChat.ServiceHelpers, as: Helpers
      alias UccChatWeb.FlexBarView, as: View

    end
  end
  import Rebel.{Core, Query, Browser}, warn: false

  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUcc.Permissions
  alias UcxUcc.Accounts
  alias UccChatWeb.MessageView

  def do_messages_args(collection, user_id, channel_id) do
    user = Accounts.get_user user_id
    collection
    |> Enum.reduce({nil, []}, fn m, {last_day, acc} ->
      day = DateTime.to_date(m.updated_at)
      msg =
        %{
          channel_id: channel_id,
          message: m.message,
          username: m.message.user.username,
          user: m.message.user,
          own: m.message.user_id == user_id,
          id: m.id,
          new_day: day != last_day,
          date: MessageView.format_date(m.message.updated_at, user),
          time: MessageView.format_time(m.message.updated_at, user),
          timestamp: m.message.timestamp
        }
      {day, [msg|acc]}
    end)
    |> elem(1)
    |> Enum.reverse
  end

  def do_pinned_messages_args(collection, user_id, channel_id) do
    user = Accounts.get_user user_id
    collection
    |> Enum.reduce({nil, []}, fn m, {last_day, acc} ->
      day = DateTime.to_date(m.updated_at)
      msg =
        %{
          channel_id: channel_id,
          message: m.message,
          username: m.message.user.username,
          user: m.message.user,
          own: m.message.user_id == user_id,
          id: m.id,
          new_day: day != last_day,
          date: MessageView.format_date(m.message.updated_at, user),
          time: MessageView.format_time(m.message.updated_at, user),
          timestamp: m.message.timestamp
        }
      {day, [msg|acc]}
    end)
    |> elem(1)
    |> Enum.reverse
  end

  def settings_form_fields(channel, user_id) do
    user = Helpers.get_user! user_id
    disabled = !Permissions.has_permission?(user, "edit-room", channel.id)
    [
      %{name: :name, label: ~g"Name", type: :text, value: channel.name, read_only: disabled},
      %{name: :topic, label: ~g"Topic", type: :text, ltype: :markdown, value: channel.topic, read_only: disabled},
      %{name: :description, label: ~g"Description", type: :text, value: channel.description, read_only: disabled},
      %{name: :private, label: ~g"Private", type: :boolean, value: channel.type == 1, read_only: disabled},
      %{name: :read_only, label: ~g"Read only", type: :boolean, value: channel.read_only, read_only: disabled},
      %{name: :archived, label: ~g"Archived", type: :boolean, value: channel.archived, read_only: disabled},
      %{name: :password, label: ~g"Password", type: :text, value: "", read_only: true},
    ]
  end

  def user_info(channel, opts \\ []) do
    show_admin = opts[:admin] || false
    direct = opts[:direct] || false
    user_mode = opts[:user_mode] || false
    view_mode = opts[:view_mode] || false

    %{direct: direct, show_admin: show_admin, blocked: channel.blocked, user_mode: user_mode, view_mode: view_mode}
  end

  def toastr(socket, action, message) when action in ~w(success warning error)a do
    message = Poison.encode message
    broadcast_js socket, "window.toastr.#{action}('#{message}')"
    socket
  end

  def get_channel_id(socket) do
    exec_js! socket, "window.ucxchat.channel_id"
  end

end

