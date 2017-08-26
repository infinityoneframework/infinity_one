defmodule UccChatWeb.UserChannel.Update do
  import Rebel.{Core, Query}, warn: false

  alias UccChat.ChannelService

  def message_header(socket, user_id, channel_id) do
    html = ChannelService.render_messages_header(user_id, channel_id)
    on = ".messages-container header>h2"
    update socket, :html, set: html, on: on
  end

  # defp render_to_string(view, template, bindings \\ []) do
  #   Phoenix.View.render_to_string view, template, bindings
  # end


end
