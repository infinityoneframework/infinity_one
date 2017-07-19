defmodule UccChat.Web.FlexBar.Helpers do
  defmacro __using__(_) do
    quote do
      use UcxUcc.Web.Gettext

      import unquote(__MODULE__)
      import Ecto.Query
      import Rebel.Query
      import Rebel.Core

      alias UcxUcc.TabBar
      alias UcxUcc.Repo
      alias UccChat.ServiceHelpers, as: Helpers
      alias UccChat.Web.FlexBarView, as: View
      alias Rebel.Query

      def open(socket, _ch, tab, panel, params) do
        user_id = socket.assigns[:user_id]
        channel_id = socket.assigns[:channel_id]
        case tab[:template] do
          nil -> %{}
          templ ->
            args = args user_id, channel_id, panel, params
            html = Phoenix.View.render_to_string(tab.view, templ, args)

            js = [
              "$('section.flex-tab').parent().addClass('opened')",
              "$('.tab-button.active').removeClass('active')",
              set_tab_button_active_js(tab.id)
            ] |> Enum.join(";")

            socket
            |> Rebel.Query.update(:html, set: html, on: "section.flex-tab")
            |> exec_js(js)
        end
        socket
      end

      def close(socket, _ch, _tab, _panel, _params) do
        exec_js(socket, """
          $('section.flex-tab').parent().removeClass('opened')
          $('.tab-button.active').removeClass('active')
          """)
        socket
      end

      def args(_, _, _, _), do: []

      defoverridable [open: 5, close: 5, args: 4]
    end
  end

  alias UccChat.ServiceHelpers, as: Helpers
  use UcxUcc.Web.Gettext

  import Rebel.Core
  alias Rebel.Query

  alias UcxUcc.Permissions

  def do_messages_args(collection, user_id, channel_id) do
    collection
    |> Enum.reduce({nil, []}, fn m, {last_day, acc} ->
      day = DateTime.to_date(m.updated_at)
      msg =
        %{
          channel_id: channel_id,
          message: m.message,
          username: m.user.username,
          user: m.user,
          own: m.message.user_id == user_id,
          id: m.id,
          new_day: day != last_day,
          date: Helpers.format_date(m.message.updated_at),
          time: Helpers.format_time(m.message.updated_at),
          timestamp: m.message.timestamp
        }
      {day, [msg|acc]}
    end)
    |> elem(1)
    |> Enum.reverse
  end

  def set_tab_button_active_js(id) do
    get_tab_button_js(id) <> ".hasClass('active')"
  end

  def get_tab_button_js(id) do
    ~s/$('.tab-button[data-id="#{id}"]')/
  end

  def tab_container(), do: ".flex-tab-container"

  def get_all_channel_online_users(channel) do
    channel
    |> get_all_channel_users
    |> Enum.reject(&(&1.status == "offline"))
  end

  def get_all_channel_users(channel) do
    Enum.map(channel.users, fn user ->
      struct(user, status: UccChat.PresenceAgent.get(user.id))
    end)
  end

  def get_channel_offline_users(channel) do
    channel
    |> get_all_channel_users
    |> Enum.filter(&(&1.status == "offline"))
  end

  def user_info(channel, opts \\ []) do
    %{
      direct: opts[:direct] || false,
      show_admin: opts[:admin] || false,
      blocked: channel.blocked,
      user_mode: opts[:user_mode] || false,
      view_mode: opts[:view_mode] || false
    }
  end

  def exec_update_fun(socket, sender, name) do
    js = ~s/$('#{this(sender)}')[0].dataset['fun'] = '#{name}'/
    exec_js socket, js
    socket
  end

  def settings_form_fields(channel, user_id) do
    user = Helpers.get_user! user_id
    disabled = !Permissions.has_permission?(user, "edit-room", channel.id)
    [
      %{name: "name", label: ~g"Name", type: :text, value: channel.name, read_only: disabled},
      %{name: "topic", label: ~g"Topic", type: :text, value: channel.topic, read_only: disabled},
      %{name: "description", label: ~g"Description", type: :text, value: channel.description, read_only: disabled},
      %{name: "private", label: ~g"Private", type: :boolean, value: channel.type == 1, read_only: disabled},
      %{name: "read_only", label: ~g"Read only", type: :boolean, value: channel.read_only, read_only: disabled},
      %{name: "archived", label: ~g"Archived", type: :boolean, value: channel.archived, read_only: disabled},
      %{name: "password", label: ~g"Password", type: :text, value: "", read_only: true},
    ]
  end
end

