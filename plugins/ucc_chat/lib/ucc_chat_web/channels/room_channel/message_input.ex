defmodule UccChatWeb.RoomChannel.MessageInput do
  use UccLogger

  alias UccChatWeb.RoomChannel.KeyStore
  alias UccChatWeb.RoomChannel.MessageInput.Client
  alias UccChatWeb.RoomChannel.Message

  require UccChatWeb.RoomChannel.Constants, as: Const

  @app_patterns       [
                        ~r/^\/([^\s]*)$/,
                        ~r/(^|\s)@([^\s]*)$/,
                        ~r/(^|\s)#([^\s]*)$/,
                        ~r/(^|\s):([^\s]*)$/
                      ]

  @app_keys            ~w(/ @ # :)
  @app_mods            [SlashCommands, Users, Channels, Emojis]
  @app_lookup          Enum.zip(@app_keys, @app_mods) |> Enum.into(%{})
  @pattern_key_lookup  Enum.zip(@app_keys, @app_patterns) |> Enum.into(%{})
  @pattern_mod_lookup  Enum.zip(@app_mods, @app_patterns) |> Enum.into(%{})

  @up_arrow            "ArrowUp"
  @dn_arrow            "ArrowDown"
  @left_arrow          "ArrowLeft"
  @right_arrow         "ArrowRight"
  @bs                  "Backspace"
  @tab                 "Tab"
  @cr                  "Enter"
  @esc                 "Escape"

  @special_keys        [@esc, @up_arrow, @dn_arrow, @left_arrow,
                        @right_arrow, @bs, @tab, @cr]

  @fn_keys             for n <- 1..15, do: "F#{n}"

  @ignore_keys         @fn_keys ++ ~w(Shift Meta Control Alt
                         PageDown PageUp Home)

  def message_keydown(socket, sender) do
    key = sender["event"]["key"]
    Logger.warn "message_keydown: #{inspect key}"
    unless key in @ignore_keys do
      handle_keydown(socket, sender, key)
    end
    socket
  end

  def handle_keydown(socket, sender, key, client \\ Client) do
    self = socket.assigns[:self]
    user_id = socket.assigns[:user_id]

    ks_key = {user_id, self}
    info = %{
      socket: socket,
      sender: sender,
      ks_key: ks_key,
      key: key,
      user_id: user_id,
      channel_id: socket.assigns[:channel_id],
      client: client
    }

    ks_key
    |> KeyStore.get
    |> trace_data(info)
    |> ensure_mb_data
    |> save_key(key)
    |> handle_in(key, info)
    |> save_mb_data(ks_key, info)
  end

  defp ensure_mb_data(nil),     do: %{keys: ""}
  defp ensure_mb_data(mb_data), do: mb_data

  defp app_pattern_match?(key, buffer) when key in @app_keys do
    Regex.match? @pattern_key_lookup[key], buffer
  end
  defp app_pattern_match?(_, _), do: false

  defp pattern_mod_match?(mod, buffer) do
    Regex.match? @pattern_mod_lookup[mod], buffer
  end

  def save_key(mb_data, key) when key in @special_keys, do: mb_data

  # def save_key(mb_data, key) when key in @app_keys do
  #   if app_pattern_match? key, mb_data.keys <> key do
  #     Logger.warn "matched"
  #     mb_data
  #   else
  #     Logger.warn "did not match"
  #     put_key mb_data, key
  #   end
  # end

  def save_key(mb_data, key) do
    put_key mb_data, key
  end

  defp trace_data(data, info) do
    Logger.warn "message_keydown: ks_key: #{inspect info.ks_key}, data: #{inspect data}"
    data
  end

  defp put_key(mb_data, key) do
    update_in(mb_data, [:keys], & &1 <> key)
  end

  defp save_mb_data(mb_data, ks_key, info) do
    KeyStore.put ks_key, mb_data
    mb_data
  end

  defp handle_in(mb_data, key, info) when key in @special_keys do
    handle_special_keys mb_data, key, info
  end

  defp handle_in(%{app: app} = mb_data, key, info) do
    if pattern_mod_match? app, mb_data.keys do
      Logger.info "matched: " <> inspect(mb_data)
      app
      |> app_module
      |> apply(:handle_in, [mb_data, key, info])
    else
      Logger.info "did not match: " <> inspect(mb_data)
      mb_data
      |> close_popup(info.socket, info)
    end
  end

  defp handle_in(mb_data, key, info) when key in @app_keys do
    if app_pattern_match? key, mb_data.keys do
      Logger.info "matched: " <> inspect(mb_data)
      key
      |> key_to_app_module
      |> apply(:new, [mb_data, key, info])
    else
      Logger.info "did not match: " <> inspect(mb_data)
      mb_data
    end
  end


  # defp handle_in({false, mb_data}, _key, _info),
  #   do: mb_data

  # default key handler
  defp handle_in(mb_data, key, _info) do
    trace "default handle_in", {mb_data, key}
    mb_data
  end

  def click_slash_popup(socket, sender) do
    Logger.error "click_slash_popup: sender: " <> inspect(sender)

    # self = socket.assigns[:self]
    # user_id = socket.assigns[:user_id]
    # # command = sender["dataset"]["name"]

    # ks_key = {user_id, self}
    # info = %{socket: socket, sender: sender, ks_key: ks_key}

    socket
  end

  ####################
  # Special key handlers

  # defp handle_special_keys({_, mb_data}, @up_arrow = _key, _info) do
  #   mb_data
  # end

  # defp handle_special_keys({_, mb_data}, @dn_arrow = _key, _info) do
  #   mb_data
  # end

  defp handle_special_keys(%{keys: ""} = mb_data, @bs, info) do
    mb_data
    |> close_popup(info.socket, info)
    |> clear_mb_data
  end

  defp handle_special_keys(mb_data, @bs = key, info) do
    mb_data
    |> update_in([:keys], &String.replace(&1, ~r/.$/, ""))
    |> check_and_call_app_module(key, info, :handle_in)
  end

  defp handle_special_keys(%{app: app} = mb_data, key, info) when key in [@tab, @cr] do
    selected = get_selected_item(info)

    app
    |> app_module
    |> apply(:handle_select, [mb_data, selected, info])
    |> close_popup(info.socket, info)
    |> clear_mb_data
  end

  defp handle_special_keys(mb_data, @tab = _key, _info) do
    mb_data
  end

  defp handle_special_keys(mb_data, @cr = _key, info) do
    assigns = info.socket.assigns

    message =
      info.socket
      |> info.client.get_message_box_value
      |> String.trim_trailing

    if message != "" do
      Message.create(message, assigns.channel_id, assigns.user_id, info.socket)
    end

    info.client.clear_message_box(info.socket)
    clear_mb_data mb_data
  end

  defp handle_special_keys(%{app: _} = mb_data, @esc, info) do
    info.client.close_popup info.socket
    Map.delete mb_data, :app
  end

  defp handle_special_keys(%{app: _} = mb_data, @dn_arrow, info) do
    info.client.run_js info.socket, "UccChat.utils.downArrow()"
    mb_data
  end

  defp handle_special_keys(%{app: _} = mb_data, @up_arrow, info) do
    info.client.run_js info.socket, "UccChat.utils.upArrow()"
    mb_data
  end

  defp handle_special_keys(mb_data, _key, _info), do: mb_data

  defp check_and_call_app_module(%{app: app} = mb_data, key, info, fun) do
    app
    |> app_module
    |> apply(fun, [mb_data, key, info])
  end

  defp check_and_call_app_module(mb_data, _key, _info, _fun) do
    mb_data
  end

  defp clear_mb_data(mb_data) do
    mb_data
    |> Map.put(:keys, "")
    |> Map.delete(:app)
  end

  defp get_selected_item(info) do
    info.client.get_selected_item info.socket
  end

  ###############
  # Helpers

  defp close_popup(mb_data, socket, info) do
    info.client.close_popup socket
    mb_data
  end

  defp app_module(app), do: Module.concat(__MODULE__, app)
  defp key_to_app_module(key), do: @app_lookup[key] |> app_module
end
