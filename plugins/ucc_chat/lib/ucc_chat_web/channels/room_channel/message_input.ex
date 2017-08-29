defmodule UccChatWeb.RoomChannel.MessageInput do
  # use UccChatWeb, :channel
  use UccLogger

  import Rebel.{Query, Core}, warn: false
  # import UcxUccWeb.Utils, only: [strip_nl: 1]

  alias Rebel.Element
  alias UccChatWeb.RoomChannel.KeyStore
  alias UccChatWeb.RoomChannel.MessageInput.Client
  alias UccChatWeb.RoomChannel.Message

  require UccChatWeb.RoomChannel.Constants, as: Const

  @ignore_keys ~w(Shift Meta Control Alt)

  @app_keys   ~w(/ @ # :)
  @app_mods   [SlashCommands, Users, Channels, Emojis]
  @app_lookup Enum.zip(@app_keys, @app_mods) |> Enum.into(%{})

  @up_arrow   "ArrowUp"
  @dn_arrow   "ArrowDown"
  @bs         "Backspace"
  @tab        "Tab"
  @cr         "Enter"
  @esc        "Esc"

  @special_keys [@esc, @up_arrow, @dn_arrow, @bs, @tab, @cr]

  def message_keydown(socket, sender) do
    key = sender["event"]["key"]
    Logger.warn "message_keydown: #{inspect key}"
    if key in @ignore_keys do
      socket
    else
      handle_keydown(socket, sender, key)
    end
  end

  # def handle_keydown(socket, %{"event" => %{"keyCode" => kc}})
  #   when kc in @ignore_keys, do: socket

  def handle_keydown(socket, sender, key) do
    self = socket.assigns[:self]
    user_id = socket.assigns[:user_id]

    ks_key = {user_id, self}
    info = %{
      socket: socket,
      sender: sender,
      ks_key: ks_key,
      key: key,
      user_id: user_id,
      channel_id: socket.assigns[:channel_id]
    }

    ks_key
    |> KeyStore.get
    |> trace_data(info)
    |> check_first
    |> save_key(key)
    |> handle_in(key, info)
    |> save_mb_data(ks_key, info)
  end

  defp check_first(nil), do: {true, %{keys: ""}}
  defp check_first(mb_data), do: {mb_data[:keys] == "" and is_nil(mb_data[:app]), mb_data}

  def save_key({true, mb_data}, key) when key in @app_keys,
    do: {true, mb_data}

  def save_key(args, key) when key in @special_keys,
    do: args

  def save_key({first, mb_data}, key),
    do: {first, update_in(mb_data, [:keys], & &1 <> key)}

  defp trace_data(data, info) do
    Logger.warn "message_keydown: ks_key: #{inspect info.ks_key}, data: #{inspect data}"
    data
  end

  defp save_mb_data(mb_data, ks_key, info) do
    KeyStore.put ks_key, mb_data
    info.socket
  end

  defp handle_in({true, mb_data}, key, info) when key in @app_keys do
    key
    |> key_to_app_module
    |> apply(:new, [mb_data, key, info])
  end

  defp handle_in(args, key, info) when key in @special_keys do
    handle_special_keys args, key, info
  end

  defp handle_in({false, %{app: app} = mb_data}, key, info) do
    app
    |> app_module
    |> apply(:handle_in, [mb_data, key, info])
  end

  defp handle_in({false, mb_data}, _key, _info),
    do: mb_data

  # default key handler
  defp handle_in({_, mb_data} = args, key, _info) do
    trace "default handle_in", {args, key}
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

  defp handle_special_keys({_, %{keys: ""} = mb_data}, @bs = _key, info) do
    mb_data
    |> close_popup(info.socket)
    |> clear_mb_data
  end

  defp handle_special_keys({_, mb_data}, @bs = key, info) do
    mb_data
    |> update_in([:keys], &String.replace(&1, ~r/.$/, ""))
    |> check_and_call_app_module(key, info, :handle_in)
  end

  defp handle_special_keys({_, %{app: app} = mb_data}, key, info) when key in [@tab, @cr] do
    selected = get_selected_item(info.socket)

    app
    |> app_module
    |> apply(:handle_select, [mb_data, selected, info])
    |> close_popup(info.socket)
    |> clear_mb_data
  end

  defp handle_special_keys({_, mb_data}, @tab = _key, _info) do
    mb_data
  end

  defp handle_special_keys({_, mb_data}, @cr = _key, info) do
    assigns = info.socket.assigns
    message = Client.get_message_box_value(info.socket)

    if message != "" do
      Message.create message, assigns.channel_id,
        assigns.user_id, info.socket
    end

    Client.clear_message_box(info.socket)
    clear_mb_data mb_data
  end

  defp handle_special_keys({_, mb_data}, @esc = _key, info) do
    Client.close_popup info.socket
    Map.delete mb_data, :app
  end

  defp handle_special_keys({_, mb_data}, @dn_arrow = _key, info) do
    exec_js info.socket, """
      var curr = document.querySelector('#{Const.selected}');
      if (!curr) {
        var list = document.querySelector('.message-popup-items');
        if (list) {
          curr = list.firstChild;
        }
      }
      if (curr) {
        var next = curr.nextSibling;
        console.log('next', next);
        if (next) {
          curr.classList.remove('selected');
          next.classList.add('selected');
        }
      }
      """ |> String.replace("\n", "")
    mb_data
  end

  defp handle_special_keys({_, mb_data}, @up_arrow = _key, info) do
    exec_js info.socket, """
      var curr = document.querySelector('#{Const.selected}');
      if (!curr) {
        var list = document.querySelector('.message-popup-items');
        if (list) {
          curr = list.lastChild;
        }
      }
      if (curr) {
        var prev = curr.previousSibling;
        console.log('prev', prev);
        if (prev) {
          curr.classList.remove('selected');
          prev.classList.add('selected');
        }
      }
      """ |> String.replace("\n", "")
    mb_data
  end


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

  defp get_selected_item(socket) do
    case Element.query_one socket, ".popup-item.selected", :dataset do
      {:ok, %{"dataset" => %{"name" => name}}} -> name
      _other -> nil
    end
  end

  ###############
  # Helpers

  defp close_popup(mb_data, socket) do
    Client.close_popup socket
    mb_data
  end

  defp app_module(app), do: Module.concat(__MODULE__, app)
  defp key_to_app_module(key), do: @app_lookup[key] |> app_module
end
