defmodule UccChatWeb.RebelChannel.Client do
  import Rebel.Query
  import Rebel.Core
  import UcxUccWeb.Utils
  import Rebel.{Core, Query}, warn: false

  alias UccChatWeb.ClientView
  alias UccChat.{MessageService, SideNavService}
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
    end
  end

  def page_loading(socket) do
    insert socket, ClientView.page_loading, prepend: "head"
    socket
  end

  def remove_page_loading(socket) do
    delete socket, "head > style"
    socket
  end

  def start_loading_animation(socket, elem) do
    socket
    |> page_loading
    |> broadcast_js("$('#{elem}').next().after('#{ClientView.loading_animation}')")
    socket
  end

  def stop_loading_animation(socket) do
    socket
    |> remove_page_loading()
    |> delete(from: ".loading-animation")
    socket
  end

  def set_ucxchat_room(socket, room, display_name, _route \\ "channels") do
    broadcast_js(socket, "window.UccChat.ucxchat.room = '#{room}'; " <>
      "window.UccChat.ucxchat.display_name = '#{display_name}'")
    |> case do
      {:ok, _} ->
        socket
      {:error, error} ->
        raise "set_ucxchat_room error: #{inspect error}"
    end
  end

  def push_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> push_history()
  end

  def push_history(socket) do
    broadcast_js(socket, "history.replaceState(history.state, " <>
      "window.UccChat.ucxchat.display_name, '/' + ucxchat.room_route " <>
      "+ '/' + window.UccChat.ucxchat.display_name)")
    |> case do
      {:ok, _} ->
        socket
      {:error, error} ->
        raise "push_history error: #{inspect error}"
    end
  end

  def replace_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> replace_history()
  end

  def replace_history(socket) do
    broadcast_js(socket, "history.replaceState(history.state, " <>
      "ucxchat.display_name, '/' + ucxchat.room_route + '/' + " <>
      "ucxchat.display_name)")
    |> case do
      {:ok, _} ->
        socket
      {:error, error} ->
        raise "replace_history error: #{inspect error}"
    end
  end

  def toastr!(socket, which, message) do
    case toastr socket, which, message do
      {:ok, _} ->
        socket
      {:error, error} ->
        Logger.error "toastr failed with error: #{inspect error}"
        socket
    end
  end

  def toastr(socket, which, message) do
    message = Poison.encode! message
    broadcast_js socket, ~s{window.toastr.#{which}(#{message});}
  end

  def broadcast_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
  end

  def set_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
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
    update socket, :html,
      set: MessageService.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
  end

  def broadcast_message_box(socket, channel_id, user_id) do
    html = MessageService.render_message_box(channel_id, user_id)
    html_str = Poison.encode! html
    do_broadcast_js socket, "console.log('user_id', '#{user_id}');"
    do_broadcast_js socket, "console.log('html', '#{html_str}');"

    update! socket, :html,
      set: html,
      on: ".room-container footer.footer"
  end

  def push_rooms_list_update(socket, channel_id, user_id) do
    user = Accounts.get_user user_id
    html = SideNavService.render_rooms_list(channel_id, user_id)
    # TODO: for testing purposes
    Logger.info "username: " <> user.username
    Logger.info html

    update socket, :html,
      set: html,
      # set: SideNavService.render_rooms_list(channel_id, user_id),
      on: "aside.side-nav .rooms-list"
  end

  def update_main_content_html(socket, view, template, bindings) do
    update socket, :html,
      set: render_to_string(view, template, bindings),
      on: ".main-content"
  end

  def scroll_bottom(socket, selector) do
    broadcast_js socket, scroll_bottom_js(selector)
    socket
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
    broadcast_js socket, set_caret_position_js(selector, start, finish)
  end

  def set_caret_position!(socket, selector, start, finish) do
    case set_caret_position(socket, selector, start, finish) do
      {:ok, result} -> result
      other -> other
    end
  end

  def set_caret_position_js(selector, start, finish) do
    """
    var elem = document.querySelector('#{selector}');
    UccUtils.setCaretPosition(elem, #{start}, #{finish});
    """ |> strip_nl
  end

  def more_channels(socket, html) do
    broadcast_js socket, more_channels_js(html)
  end

  def more_channels_js(html) do
    encoded = Poison.encode! html |> strip_nl()
    """
    $('.flex-nav section').html(#{encoded}).parent().removeClass('animated-hidden');
    $('.arrow').toggleClass('close', 'bottom');
    """
  end

end
