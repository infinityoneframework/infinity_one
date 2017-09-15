defmodule UccChatWeb.RoomChannel.MessageCog do
  use UccLogger
  use UcxUccWeb.Gettext
  use UccChatWeb.RoomChannel.Constants

  import UccChatWeb.RebelChannel.Client
  import Rebel.Core, only: [this: 1]

  alias UccChatWeb.Client
  alias UccChat.{Emoji, EmojiService, AccountService, StaredMessage, PinnedMessage}
  alias UccChatWeb.{EmojiView, MessageView}
  alias UcxUcc.Accounts


  def message_cog_click(socket, sender, client \\ Client) do
    assigns = socket.assigns
    message_id = client.closest socket, this(sender), "li.message", :id
    star_count = StaredMessage.count(assigns.user_id, message_id, assigns.channel_id)
    pin_count = PinnedMessage.count(message_id)
    opts = [stared: star_count > 0, pinned: pin_count > 0]

    Logger.info "message_cog_click id: #{message_id}, sender: #{inspect sender}"
    Logger.info "message_cog_click opts: #{inspect opts}"

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
end

