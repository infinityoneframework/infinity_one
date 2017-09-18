defmodule UccChatWeb.RoomChannel.MessageInput do
  use UccLogger

  # alias UccChatWeb.RoomChannel.KeyStore
  alias UccChatWeb.RoomChannel.MessageInput.{Client, SpecialKeys, Buffer}
  # alias UccChatWeb.RoomChannel.Message
  alias UccChatWeb.RoomChannel.MessageInput.Buffer

  use UccChatWeb.RoomChannel.Constants

  def message_keydown(socket, sender) do
    key = sender["event"]["key"]
    Logger.warn "message_keydown: #{inspect key}"
    unless key in @ignore_keys do
      handle_keydown(socket, sender, key)
    end
    socket
  end

  def handle_keydown(socket, sender, key, client \\ Client) do
    socket
    |> create_context(sender, key, client)
    |> trace_data
    |> handle_in(key)
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
    |> logit1
  end

  def logit1(cx) do
    Logger.info("app: #{inspect cx[:app]}, key: #{inspect cx.key}")
    cx
  end


  defp set_app(context, sender) do
    Logger.info "popup app: #{inspect sender}"
    context
    |> Map.put(:open?, sender["message_popup"])
    |> Map.put(:app, Module.concat(sender["popup_app"], nil))
  end

  defp trace_data(context) do
    Logger.warn "message_keydown: " <> inspect(context)
    context
  end

  ########################
  # handle_in Handlers

  defp handle_in(%{state: :ignore} = context, _key) do
    Logger.info "handle in"
    context
  end

  defp handle_in(context, key) when key in @special_keys do
    Logger.info "key: #{inspect key}, state: #{inspect context.state}"
    SpecialKeys.handle_in context, key
  end

  defp handle_in(%{state: state} = context, key) when key in @app_keys do
    Logger.info "state: #{inspect state}"
    if match = Buffer.match_app_pattern state.head do
      Logger.info "matched: "
      dispatch_handle_in(key, match, context)
    else
      Logger.info "did not match: "
      context
    end
  end

  defp handle_in(%{app: app, state: state} = context, _key) do
    Logger.info "handle in"
    if match = Buffer.pattern_mod_match? app, state.buffer do
      Logger.info "matched: "
      dispatch_handle_in(app, match, context)
    else
      Logger.info "did not match: "
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
    |> IO.inspect(label: "context")
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
    Logger.info "pattern 1 #{inspect pattern}"
    key
    |> Buffer.key_to_app
    |> dispatch_handle_in(pattern, context)
  end

  def dispatch_handle_in(module, pattern, context) when is_atom(module) do
    Logger.info "pattern 2 #{inspect pattern}, module: #{inspect module}"
    __MODULE__
    |> Module.concat(module)
    |> IO.inspect(label: "after concat")
    |> apply(:handle_in, [pattern, context])
    |> check_and_close(Map.put(context, :app, module))
  end

  def send_js(context, js) do
    context.client.send_js context.socket, js
    context
  end

end
