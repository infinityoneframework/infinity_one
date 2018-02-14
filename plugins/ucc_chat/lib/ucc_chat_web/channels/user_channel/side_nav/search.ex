defmodule UccChatWeb.UserChannel.SideNav.Search do

  import Rebel.Core

  alias UcxUccWeb.Query
  alias UccChat.SideNavService

  require Logger

  def search_click(socket, _sender) do
    Query.insert socket, :class, set: "search", on: ".side-nav .rooms-list"
  end

  def search_keydown(socket, _sender) do
    html =
      socket
      |> exec_js!("$('input.toolbar-search__input').val();")
      |> SideNavService.render_rooms_list_seach(socket.assigns.user_id, [fuzzy: true])

    Query.update(socket, :html, set: html, on: ".side-nav .rooms-list")
  end

  def search_blur(socket, _sender) do
    assigns = socket.assigns
    channel_id = if assigns.channel_id == "", do: nil, else: assigns.channel_id

    spawn fn ->
      # need to sleep here. If we don't, then the JS handler for opening a
      # clicked room will not run before the following updates the DOM.
      # Also note, if we delay too long, then the side nav won't show the
      # active room since the data here will be stale
      Process.sleep 250

      html = SideNavService.render_rooms_list(channel_id, assigns.user_id)

      socket
      |> Query.update(:value, set: "", on: "input.toolbar-search__input")
      |> Query.update(:html, set: html, on: ".side-nav .rooms-list")
      |> Query.delete(class: "search", on: ".side-nav .rooms-list")
    end
    socket
  end

end
