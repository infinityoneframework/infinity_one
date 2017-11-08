defmodule UccChatWeb.RoomChannel.MessageCog do
  use UccLogger
  use UcxUccWeb.Gettext
  use UccChatWeb.RoomChannel.Constants

  import Rebel.Core, only: [this: 1]

  alias UccChatWeb.Client
  alias UccChat.{StaredMessage, PinnedMessage}
  alias UccChatWeb.{MessageView, FlexBarView}

  def message_cog_click(socket, sender, client \\ Client) do
    assigns = socket.assigns
    message_id = client.closest socket, this(sender), "li.message", :id
    star_count = StaredMessage.count(assigns.user_id, message_id, assigns.channel_id)
    pin_count = PinnedMessage.count(message_id)
    opts = [stared: star_count > 0, pinned: pin_count > 0]

    html =
      MessageView
      |> client.render_to_string("message_cog.html", opts: opts)
      # |> Poison.encode!

    client.append(socket, ~s([id="#{message_id}"] .message-cog-container), html)
    client.send_js socket, """
      Rebel.set_event_handlers('[id="#{message_id}"]');
      $('##{message_id} .message-dropdown').click(function(e) {
        e.stopPropagation();
      })
      """
    # client.send_js socket, "$('##{message_id} .message-cog-container').append(#{html})"
    socket
  end

  def flex_message_cog_click(socket, sender, client \\ Client) do
    # assigns = socket.assigns
    message_id = client.closest socket, this(sender), "li.message", :id

    html =
      FlexBarView
      |> client.render_to_string("flex_cog.html", [])

    client.append(socket, ~s([id="#{message_id}"] .message-cog-container), html)
    client.send_js socket, """
      Rebel.set_event_handlers('[id="#{message_id}"]');
      $('##{message_id} .message-dropdown').click(function(e) {
        e.stopPropagation();
      })
      """
    # client.send_js socket, "$('##{message_id} .message-cog-container').append(#{html})"
    socket
  end

  def jump_to_message(socket, sender, client \\ Client) do
    id = sender["rebel_id"] |> IO.inspect(label: "rebel_id")
    client.send_js socket, """
      var ts = $('[rebel-id="#{id}"]').closest('li.message').data('timestamp');
      var target = $('.messages-box li[data-timestamp="' + ts + '"]');
      if (target.offset()) {
        UccChat.roomManager.scroll_to(target, -400);
      } else {
        UccChat.roomHistoryManager.getSurroundingMessages(ts);
      }
      """
      socket
      |> close_cog(sender, client)
      |> message_box_focus(client)
    socket
  end

  def close_cog(socket, sender, client \\ Client) do
    client.send_js socket, ~s/$('#{Rebel.Core.this(sender)}').closest('.message-dropdown').remove()/
    socket
  end

  def message_box_focus(socket, client \\ Client) do
    client.send_js socket, ~s/UccChat.roomManager.message_box_focus();/
    socket
  end
end

