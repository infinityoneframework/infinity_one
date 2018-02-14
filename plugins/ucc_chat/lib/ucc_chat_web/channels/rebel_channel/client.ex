defmodule UccChatWeb.RebelChannel.Client do
  @moduledoc """
  Library to handle interaction with the client using the Rebel library.

  This module contains a bunch of helper functions to abstract away the
  details of client interaction. It is uses by a number of application
  modules.

  It contains some generic, and reusable functions, as will as some
  very specialized ones.
  """
  import Rebel.Query
  import Rebel.Core
  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false

  alias Rebel.SweetAlert
  alias UccChatWeb.{ClientView, SharedView, SideNavView}
  alias UccChat.{SideNavService}
  alias UcxUccWeb.Query
  alias UccChatWeb.RoomChannel.Message
  alias UcxUcc.Accounts

  require Logger

  def do_exec_js(socket, js) do
    case exec_js(socket, js) do
      {:ok, res} ->
        res
      {:error, error} = res ->
        Logger.error "Problem with exec_js #{js}, error: #{inspect error}"
        res
    end
  end

  def do_broadcast_js(socket, js) do
    case broadcast_js(socket, js) do
      {:ok, res} ->
        res
      {:error, error} = res ->
        Logger.error "Problem with broadcast_js #{js}, error: #{inspect error}"
        res
      socket ->
        socket
    end
  end

  def page_loading(socket) do
    html = ClientView.page_loading() |> Poison.encode!
    async_js socket, "$('head').prepend(#{html});"
  end

  def remove_page_loading(socket) do
    delete socket, "head > style"
    socket
  end

  def start_loading_animation(socket, elem) do
    socket
    |> page_loading
    |> async_js("$('#{elem}').next().after('#{ClientView.loading_animation}')")
  end

  def stop_loading_animation(socket) do
    socket
    |> remove_page_loading()
    |> delete(from: ".loading-animation")
  end

  def set_ucxchat_room(socket, room, display_name, _route \\ "channels") do
    async_js(socket, "window.UccChat.ucxchat.room = '#{room}'; " <>
      "window.UccChat.ucxchat.display_name = '#{display_name}'")
  end

  def push_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> push_history()
  end

  def push_history(socket) do
    async_js(socket, "history.replaceState(history.state, " <>
      "window.UccChat.ucxchat.display_name, '/' + ucxchat.room_route " <>
      "+ '/' + window.UccChat.ucxchat.display_name)")
  end

  def replace_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> replace_history()
  end

  def replace_history(socket) do
    async_js(socket, "history.replaceState(history.state, " <>
      "ucxchat.display_name, '/' + ucxchat.room_route + '/' + " <>
      "ucxchat.display_name)")
  end

  def toastr!(socket, which, message) do
    Logger.info "toastr! has been been deprecated! Please use toastr/3 instead."
    toastr socket, which, message
  end

  def toastr(socket, which, message) do
    message = Poison.encode! message
    async_js socket, ~s{window.toastr.#{which}(#{message});}
  end

  def broadcast_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
  end

  def set_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
  end

  def set_room_title(socket, channel_id, display_name) do
    async_js socket, ~s/$('section[id="chat-window-#{channel_id}"] .room-title').text('#{display_name}')/
  end

  def update_room_icon_js(room_name, icon_name) do
    """
    var elems = document.querySelectorAll('i.room-#{room_name}');
    for (var i=0; i < elems.length; i++) {
      var elem = elems[i];
      elem.className = elem.className.replace(/icon-([a-zA-Z\-_]+)/, 'icon-#{icon_name}');
    }
    """ |> String.replace("\n", "")
  end

  def push_account_header(socket, %{} = user) do
    status = UccChat.PresenceAgent.get user.id

    html = render_to_string SideNavView, "account_box_info.html",
      status: status, user: user

    Query.update socket, :replaceWith, set: html, on: ".side-nav .account-box > .info"
  end

  def push_account_header(socket, user_id) do
    user =
      user_id
      |> Accounts.get_user()
      |> UcxUcc.Hooks.preload_user(Accounts.default_user_preloads())
    push_account_header(socket,  user)
  end

  def push_side_nav_item_link(socket, _user, room) do
    html = render_to_string SideNavView, "chat_room_item_link.html", room: room

    Query.update socket, :replaceWith, set: html,
      on: ~s/.side-nav a.open-room[data-name="#{room.user.username}"]/
  end

  def push_messages_header_icons(socket, chatd) do
    html =
      chatd
      |> SharedView.messages_header_icons()
      |> Phoenix.HTML.safe_to_string()

    Query.update socket, :replaceWith, set: html,
      on: ~s/.messages-container .messages-header-icons/
  end

  def broadcast_room_visibility(socket, payload, false) do
    do_broadcast_js socket, remove_room_from_sidebar(payload.room_name)
  end

  def broadcast_room_visibility(socket, payload, true) do
    push_rooms_list_update socket, payload.channel_id, socket.assigns.user_id
  end

  def remove_room_from_sidebar(room_name) do
    """
    var elem = document.querySelector('aside.side-nav [data-name="#{room_name}"]');
    if (elem) { elem.parentElement.remove(); }
    """ |> String.replace("\n", "")
  end

  def push_message_box(socket, channel_id, user_id) do
    socket
    |> Query.update(:html, set: Message.render_message_box(channel_id, user_id), on: ".room-container footer.footer")
    |> async_js("$('textarea.input-message').focus().autogrow();")
  end

  def broadcast_message_box(socket, channel_id, user_id) do
    html = Message.render_message_box(channel_id, user_id)

    socket
    |> update!(:html, set: html, on: ".room-container footer.footer")
    |> broadcast_js("$('textarea.input-message').autogrow();")
  end

  def push_rooms_list_update(socket, channel_id, user_id) do
    html = SideNavService.render_rooms_list(channel_id, user_id)
    Query.update socket, :html,
      set: html,
      on: "aside.side-nav .rooms-list"
  end

  def update_main_content_html(socket, view, template, bindings) do
    Query.update socket, :html,
      set: render_to_string(view, template, bindings),
      on: ".main-content"
  end

  def update_user_avatar(socket, username, url) do
    async_js socket, ~s/$('.avatar[data-user="#{username}"] .avatar-image').css('background-image', 'url(#{url}');/
  end

  def scroll_bottom(socket, selector) do
    async_js socket, scroll_bottom_js(selector)
  end

  def scroll_bottom_js(selector) do
    """
    var elem = document.querySelector('#{selector}');
    elem.scrollTop = elem.scrollHeight - elem.clientHeight;
    """ |> strip_nl()
  end

  def get_caret_position(socket, selector) do
    exec_js socket, get_caret_position_js(selector)
  end

  def get_caret_position!(socket, selector) do
    case get_caret_position(socket, selector) do
      {:ok, result} -> result
      {:error, _} -> %{}
    end
  end

  def get_caret_position_js(selector) do
    """
    var elem = document.querySelector('#{selector}');
    UccUtils.getCaretPosition(elem);
    """ |> strip_nl
  end

  def set_caret_position(socket, selector, start, finish) do
    async_js socket, set_caret_position_js(selector, start, finish)
  end

  def set_caret_position!(socket, selector, start, finish) do
    case set_caret_position(socket, selector, start, finish) do
      {:ok, result} -> result
      other -> other
    end
  end


  def update_flex_channel_name(socket, name) do
    Query.update(socket, :text, set: name, on: ~s(.current-setting[data-edit="name"]))
  end

  def set_caret_position_js(selector, start, finish) do
    """
    var elem = document.querySelector('#{selector}');
    UccUtils.setCaretPosition(elem, #{start}, #{finish});
    """ |> strip_nl
  end

  def more_channels(socket, html) do
    # async_js socket, more_channels_js(html)
    socket
    |> Query.update(:html, set: html, on: ".flex-nav section")
    |> async_js("$('.flex-nav section').parent().removeClass('animated-hidden')")
    |> async_js("$('.arrow').toggleClass('close', 'bottom');")
  end

  def more_channels_js(html) do
    encoded = Poison.encode! html |> strip_nl()
    """
    $('.flex-nav section').html(#{encoded}).parent().removeClass('animated-hidden');
    $('.arrow').toggleClass('close', 'bottom');
    """
  end

  @default_swal_model_opts [
    showCancelButton: true, closeOnConfirm: false, closeOnCancel: true,
    confirmButtonColor: "#DD6B55"
  ]

  @doc """
  Show a SweetAlert modal box.
  """
  # @spec swal_model(Phoenix.Socket.t, String.t, String.t, String.t String.t || nil, Keword.t) :: Phoenix.Socket.t
  def swal_model(socket, title, body, type, confirm_text, opts \\ []) do
    {swal_opts, callbacks}  = Keyword.pop opts, :opts, []
    swal_opts = Keyword.merge @default_swal_model_opts, swal_opts
    swal_opts =
      if confirm_text do
        Keyword.merge [confirmButtonText: confirm_text] , swal_opts
      else
        swal_opts
      end

    SweetAlert.swal_modal socket, title, body, type, swal_opts, callbacks
  end

  @default_swal_opts [
    timer: 3000, showConfirmButton: false
  ]

  def swal(socket, title, body, type, opts \\ []) do
    opts = Keyword.merge @default_swal_opts, opts
    SweetAlert.swal(socket, title, body, type, opts)
  end


  def update_client_account_setting(socket, :view_mode, value) do
    class =
      case value do
        1 -> ""
        2 -> "cozy"
        3 -> "compact"
      end
    class = "messages-box " <> class

    async_js socket, ~s/$('.messages-container .messages-box').attr('class', '#{class}')/
  end

  def update_client_account_setting(socket, field, value) when field in ~w(hide_avatars hide_usernames)a do
    class = account_settings_to_class field
    cmd =
      if value do
        ~s/addClass('#{class}')/
      else
        ~s/removeClass('#{class}')/
      end

    async_js socket, ~s/$('.messages-container .wrapper').#{cmd}/

  end

  defp account_settings_to_class(:hide_usernames), do: "hide-usernames"
  defp account_settings_to_class(:hide_avatars), do: "hide-avatars"

end
