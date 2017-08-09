# defmodule Mscs.ClientProxy.Macros do
#   @moduledoc """
#   Macros to support `ClientProxy`
#   """

#   @env Mix.env

#   defmacro __using__(_opts \\ []) do
#     quote do
#       import unquote(__MODULE__)
#     end
#   end

#   @doc """
#   Macro to locate desired `Endpoint.broadcast/3` based on `Mix.env`

#   This macro uses:

#   * `EndPoint.broadcast` - for :prod
#   * `Application.get_env :mscs, :client_proxy_broadcast` for `:dev` and `:test`
#     * Defaults to the endpoint if the config is not set

#   """
#   defmacro do_broadcast(topic, message, data) do
#     if env == :prod do
#       quote do
#         Mscs.ClientProxy.broadcast unquote(topic), unquote(message), unquote(data)
#       end
#     else
#       quote do
#         proxy = Application.get_env(:mscs, :client_proxy_broadcast, &Mscs.ClientProxy.broadcast/3)
#         proxy.(unquote(topic), unquote(message), unquote(data))
#       end
#     end
#   end

#   def env, do: @env
# end

# defmodule Mscs.ClientProxy do
#   @moduledoc """
#   Proxy the state and communications for the `ClientChannel`

#   The proxy handles the client state (display, icons, and lamps)
#   for the web client. It also has a `render_client` function that
#   updates the client state if the client requests a refresh (page load).

#   The `render_client` automatically determines what state to send and
#   the required channel commands based on the fields defined in def new.

#   It should automatically handle new categories by appending them to
#   adding the defaults to `new`.

#   ## Examples

#   Under normal cases, use the `put_and_send/4` and `put_and_send/5`
#   APIs to update the client, and store the returned proxy in the
#   `GenServer` state.

#       alias Mscs.ClientProxy, as: Proxy

#       new_state = state
#       |> struct(proxy: Proxy.put_and_send(state.proxy, :key,
#           :led_update, "fk-mute", state: "on"))

#   Update the client state.

#       Proxy.refresh_client Proxy.new

#   """
#   require Logger
#   import Kernel, except: [to_string: 1, send: 1]
#   import Mscs.Utils
#   use Mscs.ClientProxy.Macros

#   @debug false

#   @doc """
#   Create a new ClientProxy

#   Use the `new/0` function instead of `%{}`. I found some
#   compile dependencies trying to add defaults otherwise.

#   Add the initialization of new categories below.
#   """
#   def new do
#     %{
#       id: "1",
#       display: %{
#         line: Mscs.ClientSm.Utils.init_keys(3, &__MODULE__.init_display_line/2),
#         soft_key: Mscs.ClientSm.Utils.init_keys(5, &__MODULE__.init_default/2),
#         context: %{text: ""},
#         pk: Mscs.ClientSm.Utils.init_keys(5, &__MODULE__.init_default/2),
#         time_and_date_download: %{text: ""},
#         time_and_date_format: %{time: 0, date: 0},
#         status_bar_icon_update: HashDict.new,
#       },
#       audio: %{
#         stream_based_tone_frequency_download: HashDict.new,
#         stream_based_tone_cadence_download: HashDict.new,
#         stream_based_tone_on: HashDict.new,
#         stream_based_tone_off: HashDict.new,
#         open_audio_stream: HashDict.new,
#         close_audio_stream: HashDict.new,
#         alerting_tone_configuration: HashDict.new,
#         special_tone_configuration: HashDict.new,
#         paging_tone_cadence_download: HashDict.new,
#         paging_tone_configuration: HashDict.new,
#         mute_unmute: HashDict.new,
#         transducer_tone_on: HashDict.new,
#         transducer_tone_off: HashDict.new,
#         connect_transducer: HashDict.new,
#         transducer_tone_volume: HashDict.new,
#         offer: %{from: "", to: ""},
#         client_devices: %{}
#       },
#       key: %{
#         led_update: HashDict.new,
#         icon_update: HashDict.new,
#         disable: HashDict.new,
#         enable: HashDict.new,
#         local_feedback: %{option: :none}
#       },
#       basic: %{
#         connected: %{success: true},
#       },
#       network: %{
#         reset_watchdog: %{timeout: 0},
#         soft_reset: %{}
#       },
#       call_state: %{
#         active: %{state: false},
#         end_call: %{state: false},
#         dialtone: %{state: false}
#       }
#     }
#   end
#   def new(opts), do: Enum.into(opts, new)

#   @doc """
#   Send all the current state to the client channel
#   """
#   def refresh_client(proxy) do
#     for category <- get_categorys(proxy) do
#       handle_category(proxy, category)
#     end
#     proxy
#   end

#   @doc """
#   Send the message and save it to the proxy.

#   Returns a new proxy with the saved state.

#   ## Parameters

#       put_and_send(proxy, category, field, key, options \\ [])

#   * `options` is a keyword list of fields that will be passed to the
#     client. For example:

#       `put_and_send(proxy, :key, :led_update, "fk-mute", state: "on")`

#     sends message `key:led_update`, with:

#     * `msg.key` equal to "fk-mute"
#     * `msg.state` equal to "on"

#     Note: the key is automatically populated in the message.

#   ## Examples

#   Send a non-indexed message:

#       ClientProxy.put_and_send(proxy, :display, :context, text: text)

#   Send a key base message:

#       ClientProxy.put_and_send(proxy, :display, :pk, 1, text: text)
#   """
#   def put_and_send(%{} = proxy, category, field) do
#     n = normalize(category, field)
#     proxy
#     |> _put(n)
#     |> _send(n)
#   end
#   def put_and_send(%{} = proxy, category, field, opts) do
#     n = normalize(category, field, opts)
#     proxy
#     |> _put(n)
#     |> _send(n)
#   end
#   def put_and_send(%{} = proxy, category, field, key, opts) do
#     n = normalize(category, field, key, opts)
#     proxy
#     |> _put(n)
#     |> _send(n)
#   end

#   @doc """
#   Save the message to the proxy's state.
#   """
#   def put(proxy, category, field) do
#     _put(proxy, normalize(category, field))
#   end
#   def put(proxy, category, field, opts) do
#     _put(proxy, normalize(category, field, opts))
#   end
#   def put(proxy, category, field, key, opts) do
#     _put(proxy, normalize(category, field, key, opts))
#   end

#   defp _put(proxy, {category, field, opts}) do
#     put_in proxy, [category, field], opts
#   end
#   defp _put(proxy, {category, field, key, opts}) do
#     update_in proxy, [category, field], &(Dict.put(&1, key, opts))
#   end
#   defp _put(proxy, _), do: proxy

#   @doc """
#   Gets an item from a proxy.

#   ## Examples

#       ClientProxy.get(proxy, :display_write, :context)
#       # %{text: "My context"}

#       ClientProxy.get(proxy, :key, :led_update, "fk-mute")
#       # %{key: "fk-mute", state: "off"}
#   """
#   def get(proxy, category, field), do: get_in(proxy, [category, field])
#   def get(proxy, category, field, key) do
#     get_in(proxy, [category, field])
#     |> Dict.get(key)
#   end
#   def get(proxy, {category, field}) do
#     get_in proxy, [category, field]
#   end
#   def get(proxy, {category, field, key}) do
#     get_in(proxy, [category, field])
#     |> Dict.get(key)
#   end


#   @doc """
#   Delete an item from the proxy.

#   Sets the item to nil, so refresh_client will not send the message.
#   """
#   def delete(proxy, category, field) do
#     put_in proxy, [category, field], nil
#   end
#   def delete(proxy, category, field, key) do
#     update_in proxy, [category, field], &(Dict.delete(&1, key))
#   end

#   @doc """
#   Write a message to the channel without validating
#   """
#   def write(proxy, category, field, opts) when is_list(opts) do
#     write(proxy, category, field, Enum.into(opts, %{}))
#   end
#   def write(proxy, category, field, opts) do
#     notify_client proxy.id, topic(category, field), opts
#     proxy
#   end

#   @doc """
#   Send a message with the `ClientChannel`
#   """
#   def send(proxy, category, field, opts) do
#     _send(proxy, normalize(category, field, opts))
#   end
#   def send(proxy, category, field, key, opts) do
#     _send(proxy, normalize(category, field, key, opts))
#   end

#   defp _send(proxy, {_, _, nil}), do: proxy
#   defp _send(proxy, {_, _, %{local: true}}), do: proxy
#   defp _send(proxy, {_, _, _, nil}), do: proxy
#   defp _send(proxy, {_, _, _, %{local: true}}), do: proxy
#   defp _send(proxy, {category, field, opts}) do
#     if valid_field?(proxy, category, field) do
#       if opts, do: notify_client(proxy.id, topic(category, field), opts)
#     end
#     proxy
#   end
#   defp _send(proxy, {category, field, _key, opts}) do
#     _send(proxy, {category, field, opts})
#   end
#   defp _send(proxy, _), do: proxy

#   defp topic(category, field) do
#     Atom.to_string(category) <> ":" <> Atom.to_string(field)
#   end

#   def broadcast(topic, message, data) do
#     debug fn -> "Proxy broadcast topic: #{topic}, msg: #{message}, data: #{inspect data}" end
#     Mscs.Endpoint.broadcast topic, message, data
#   end

#   defp handle_category(proxy, category) do
#     category_map = Map.get(proxy, category)
#     for {key, value} <- category_map |> Map.to_list do
#       handle_field(proxy, category, key, value)
#     end
#   end

#   defp handle_field(proxy, category, field, value) do
#     # Logger.warn "handle_field: cat: #{category}, key: #{key}"
#     case value do
#       %HashDict{} = dict ->
#         # Logger.warn "handle_field dict: cat: #{category}, key: #{key} value: #{inspect value}"
#         Dict.to_list(dict)
#         |> Enum.each(fn({key, map}) ->
#           send proxy, category, field, key, map
#         end)
#       map when is_map(map) ->
#         unless Map.to_list(map) == [], do: send(proxy, category, field, map)
#       _ ->
#         Logger.warn "handle_field other: cat: #{category}, field: #{field} value: #{inspect value}"
#         nil
#     end
#   end

#   defp get_categorys(proxy) do
#     Map.delete(proxy, :id)
#     |> Map.keys
#   end

#   @doc false
#   def init_display_line(line, text),
#     do: %{key: line, text: to_string(text), position: 0}

#   @doc false
#   def init_default(line, text),
#     do: %{key: line, text: to_string(text)}

#   defp notify_client(id, message, data) do
#     topic = "mscs:client-" <> id
#     # Logger.warn "broadcast notify_client: topic: #{inspect topic}," <>
#     #  " message: #{inspect message}, data: #{inspect data}"
#     do_broadcast topic, message, data
#   end

#   defp valid_field?(proxy, category, field) do
#     not (get_in(proxy, [category, field]) |> is_nil)
#   end

#   defp normalize(category, field), do: normalize(category, field, %{})

#   defp normalize(category, field, %{} = opts), do: {category, field, opts}
#   defp normalize(category, field, opts) when is_list(opts),
#     do: normalize(category, field, Enum.into(opts, %{}))
#   defp normalize(category, field, key),
#     do: normalize(category, field, key, %{})

#   defp normalize(category, field, key, %{key: key} = opts), do: {category, field, key, opts}
#   defp normalize(category, field, key, %{} = opts),
#     do: {category, field, key, Map.put(opts, :key, key)}
#   defp normalize(category, field, key, opts) when is_list(opts),
#     do: normalize(category, field, key, Enum.into(opts, %{}))

#   defp debug(msg) do
#     if @debug, do: Logger.debug(msg)
#   end

# end
