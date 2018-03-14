defmodule OneChatWeb.RoomChannel.MessageInput do
  use OneLogger
  use OneChatWeb.RoomChannel.Constants

  alias OneChatWeb.RoomChannel.MessageInput.{SpecialKeys, Buffer}
  alias OneChatWeb.RoomChannel.{Message, Channel}
  alias OneChatWeb.Client

  def message_keydown(socket, sender) do
    key = sender["event"]["key"]
    unless key in @ignore_keys do
      handle_keydown(socket, sender, key)
    end
    socket
  end

  def message_send(socket, _sender, client \\ Client) do
    Logger.warn "deprecated"

    body = socket |> client.get_message_box_value |> String.trim_trailing
    if client.editing_message?(socket) do
      Message.update_message(socket, body, client)
    else
      Message.new_message(socket, body, client)
    end
    Channel.stop_typing socket
    socket
  end

  def handle_keydown(socket, sender, key, client \\ Client) do
    socket
    |> create_context(sender, key, client)
    |> trace_data
    |> typing_notification
    |> handle_in(key)
  end

  def typing_notification(%{sender: sender} = context) do
    if sender["value"] == "" do
      Channel.start_typing context.socket
    end
    context
  end

  def create_context(socket, sender, key, client \\ Client) do
    %{
      socket: socket,
      sender: sender,
      key: key,
      user_id: socket.assigns[:user_id],
      channel_id: socket.assigns[:channel_id],
      client: client,
    }
    |> Buffer.add_buffer_state(sender, key)
    |> set_app(sender)
    |> set_message_box_buttions(key, client)
    |> logit1
  end

  def logit1(cx) do
    cx
    # |> IO.inspect(label: "cx")
  end


  defp set_app(context, sender) do
    # Logger.info "popup app: #{inspect sender}"
    context
    |> Map.put(:open?, sender["message_popup"])
    |> Map.put(:app, Module.concat(sender["popup_app"], nil))
  end

  defp trace_data(context) do
    context
  end

  defp set_message_box_buttions(context, key, client) do
    socket = context.socket
    sender = context.sender
    len = sender["text_len"]
    dirty = sender["class"] =~ "dirty"
    cond do
      dirty and (len == 0 or (len == 1 and client.get_message_box_value(socket) == "")) ->
        client.set_inputbox_buttons(socket, false)
      not dirty and not (key == @bs and len == 0) ->
        client.set_inputbox_buttons(socket, true)
      true ->
        nil
    end
    context
  end

  ########################
  # handle_in Handlers

  defp handle_in(%{state: :ignore} = context, _key) do
    # Logger.info "handle in"
    context
  end

  defp handle_in(context, key) when key in @special_keys do
    # Logger.info "key: #{inspect key}, state: #{inspect context.state}"
    SpecialKeys.handle_in context, key
  end

  defp handle_in(%{state: state} = context, key) when key in @app_keys do
    # Logger.info "state: #{inspect state}"
    if match = Buffer.match_app_pattern state.head do
      # Logger.info "matched: "
      dispatch_handle_in(key, match, context)
    else
      # Logger.info "did not match: "
      context
    end
  end

  defp handle_in(%{app: app, state: state} = context, _key) do
    # Logger.info "handle in"
    if match = Buffer.pattern_mod_match? app, state.head do
      # Logger.info "matched: "
      dispatch_handle_in(app, match, context)
    else
      # Logger.info "did not match: "
      check_and_close :close, context
    end
  end

  # default key handler
  defp handle_in(context, key) do
    trace "default handle_in", {key, context.state}
    context
  end

  def handle_select(%{state: state, app: app} = context, selected) do
    buffer = Buffer.replace_word(state.buffer, selected, state.start)
    app
    |> Buffer.app_module
    |> apply(:handle_select, [buffer, selected, context])
    close_popup(context)
    context
  end

  def click_popup(socket, sender, client \\ Client) do
    # Logger.info "click_slash_popup: sender: " <> inspect(sender)
    socket
    |> create_context(sender, @cr, client)
    |> handle_select(sender["dataset"]["name"])
  end

  def get_selected_item(context) do
    context.client.get_selected_item context.socket
  end

  ###############
  # Helpers

  def close_popup(context) do
    context.client.close_popup context.socket
    Map.delete context, :app
  end

  def check_and_close(:close, context) do
    context.client.close_popup context.socket

    Map.delete context, :app
  end

  def check_and_close(_, context) do
    context
  end

  def dispatch_handle_in(key, pattern, context) when is_binary(key) do
    # Logger.info "pattern 1 #{inspect pattern}"
    key
    |> Buffer.key_to_app
    |> dispatch_handle_in(pattern, context)
  end

  def dispatch_handle_in(module, pattern, context) when is_atom(module) do
    # Logger.info "pattern 2 #{inspect pattern}, module: #{inspect module}"
    __MODULE__
    |> Module.concat(module)
    |> apply(:handle_in, [pattern, context])
    |> check_and_close(Map.put(context, :app, module))
  end

  def broadcast_js(context, js) do
    context.client.broadcast_js context.socket, js
    context
  end

end
