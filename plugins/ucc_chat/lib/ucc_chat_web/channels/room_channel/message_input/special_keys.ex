defmodule UccChatWeb.RoomChannel.MessageInput.SpecialKeys do

  alias UccChatWeb.RoomChannel.MessageInput
  alias UccChatWeb.RoomChannel.Message
  alias UccChatWeb.RoomChannel.MessageInput.Buffer
  alias MessageInput.SlashCommands

  use UccChatWeb.RoomChannel.Constants
  require Logger

  def handle_in(%{open?: true, state: %{buffer: ""}} = context, @bs) do
    MessageInput.close_popup(context)
  end

  def handle_in(context,  key) when key in [@bs, @left_arrow, @right_arrow] do
    # Logger.info "state: #{inspect context.state}"
    case Buffer.match_all_patterns context.state.head do
      nil ->
        Logger.info "got nil"
        MessageInput.close_popup(context)
      {pattern, key} ->
        Logger.info "pattern: #{inspect {pattern, key}}"
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
    # Logger.info "cr event: #{inspect context.sender["event"]}"
    if SlashCommands.Commands.run(context.state.buffer, context.sender, context.socket) do
      unless context.sender["event"]["shiftKey"] do
        if editing?(context.sender) do
          Message.edit_message(context.socket, context.sender, context.client)
        else
          Message.new_message(context.socket, context.sender, context.client)
        end
      end
    end
  end


  def handle_in(%{app: _, open?: true} = context, @esc) do
    MessageInput.close_popup context
  end

  def handle_in(context, @esc) do
    Message.cancel_edit context.socket, context.sender, context.client
  end

  def handle_in(%{app: _} = context, @dn_arrow) do
    # Logger.info "down arrow"
    MessageInput.send_js context, "UccUtils.downArrow()"
  end

  def handle_in(%{app: _, open?: true} = context, @up_arrow) do
    # Logger.info "up arrow"
    MessageInput.send_js context, "UccUtils.upArrow()"
  end

  def handle_in(context, @up_arrow) do
    Message.open_edit context.socket
  end

  def handle_in(context, _key), do: context

  defp editing?(%{"classes" => classes}) do
    Enum.any? classes, fn {_, class} -> class == "editing" end
  end

end
