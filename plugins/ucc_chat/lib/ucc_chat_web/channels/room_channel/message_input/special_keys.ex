defmodule UccChatWeb.RoomChannel.MessageInput.SpecialKeys do

  alias UccChatWeb.RoomChannel.MessageInput
  alias UccChatWeb.RoomChannel.Message
  alias UccChatWeb.RoomChannel.MessageInput.Buffer
  alias MessageInput.SlashCommands
  alias UccChat.MessageService

  use UccChatWeb.RoomChannel.Constants
  require Logger

  def handle_in(%{open?: true, state: %{buffer: ""}} = context, @bs) do
    MessageInput.close_popup(context)
    MessageService.stop_typing context.socket
  end

  def handle_in(context,  key) when key in [@bs, @left_arrow, @right_arrow] do
    # Logger.info "state: #{inspect context.state}"
    if key == @bs and context.sender["text_len"] <= 1 do
      MessageService.stop_typing context.socket
    end

    case Buffer.match_all_patterns context.state.head do
      nil ->
        Logger.debug "got nil"
        MessageInput.close_popup(context)
      {pattern, key} ->
        Logger.debug "pattern: #{inspect {pattern, key}}"
        MessageInput.dispatch_handle_in(key, pattern, context)
    end
  end

  def handle_in(%{app: _app, open?: true} = context, key) when key in [@tab, @cr] do
    MessageInput.handle_select context, MessageInput.get_selected_item(context)
  end

  def handle_in(context, @tab) do
    context
  end

  def handle_in(context, @cr) do
    # The following is a little tricky. SlashCommands.Commands.run returns
    # true if further processing is required. When false, its indicating
    # that the cr key should be ignored.
    if SlashCommands.Commands.run(context.state.buffer, context.sender, context.socket) do
      unless context.sender["event"]["shiftKey"] do
        if editing?(context.sender) do
          Message.edit_message(context.socket, context.sender["value"], context.client)
        else
          # this is the case for a new message to be posted
          Message.new_message(context.socket, context.sender["value"], context.client)
        end
        MessageService.stop_typing context.socket
      end
    end
  end

  def handle_in(%{app: _, open?: true} = context, @esc) do
    MessageInput.close_popup context
  end

  def handle_in(context, @esc) do
    Message.cancel_edit context.socket, context.client
  end

  def handle_in(%{app: _} = context, @dn_arrow) do
    # Logger.info "down arrow"
    MessageInput.async_js context, "UccUtils.downArrow()"
  end

  def handle_in(%{app: _, open?: true} = context, @up_arrow) do
    # Logger.info "up arrow"
    MessageInput.async_js context, "UccUtils.upArrow()"
  end

  def handle_in(context, @up_arrow) do
    # only open message for editing if the text area is blank.
    if context.sender["text_len"] == 0 do
      Message.open_edit context.socket
    end
  end

  def handle_in(context, _key), do: context

  defp editing?(%{"classes" => classes}) do
    Enum.any? classes, fn {_, class} -> class == "editing" end
  end

end
