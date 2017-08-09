# defmodule Mscs.ClientSm do
#   @moduledoc """
#   Handles the state of an active Client connection

#   This module is responsible for the registration and signaling of a
#   Client connection.
#   """
#   require Logger
#   require Mscs.UnistimConstants
#   require Mscs.ClientSm.Utils

#   use Bitwise
#   import Mscs.ClientSm.Utils
#   alias Mscs.ClientContextManager, as: State
#   alias Mscs.ClientAgent
#   alias Mscs.ClientProxy, as: Proxy
#   alias Mscs.ClientManager
#   alias Mscs.SystemAgent
#   alias Mscs.Helpers
#   alias Mscs.WebRtc.Sdp
#   alias Mscs.UnistimConstants, as: UC

#   @state_timeout             15000
#   @license_timeout           5000
#   @max_unistim_state_timeout 15
#   @unistim_connect_timeout   3500
#   @unistim_port_base         18000
#   @watchdog_timer_scaler     1000
#   @ignore_unistim_logging_msgs [{:reset_watchdog}]
#   @ignore_client_msgs        [{:stats_resp}]
#   @max_client_retries        10
#   @handset_apb               1
#   @headset_apb               2
#   @handsfree_apb             3
#   @no_license                1

#   @aem_fw_version            (Mix.Project.config[:version] |> String.to_char_list) ++ [0]
#   @aem_device_1              UC.min_aem_device_id
#   @aem_device_2              UC.min_aem_device_id+1
#   @aem_device_3              UC.min_aem_device_id+2
#   @aem_device_4              UC.min_aem_device_id+3
#   @base_prgm_keys            24

#   defmodule Context do
#     Code.ensure_loaded(Mscs.ClientSm.Utils)

#     @fw_version                "2010260"
#     @fw_version_m              "201026M"
#     @client_name               "MSC"
#     @phase                     0x30 # i2050 phase = 6
#     @device_type_msc           0x21
#     @default_call_state        %{end_call: false, active: false, pk_max: 0, pk_state: %{}}

#     # IT type 20 phase 6 (6 prog. keys, 3 display lines, date 1) state 2

#     defstruct supervisor: nil, unistim: nil, mac: 0, ucx_ip: '', ucx_port: 0,
#               serial_no: [0, 0, 0, 0, 0, 0],
#               device_name: @client_name, phase: @phase,
#               terminal_id: [0xff, 0xff, 0xff, 0xff], uptime: 0,
#               device_type: @device_type_msc, watchdog_timer: nil, headset: false,
#               hookswitch: :on, user_activity_timer: nil, user_activity_timeout: 0,
#               user_activity_timer_on: false, device_data: %Mscs.DeviceData{},
#               core_fw_ver: @fw_version,
#               icon_state: HashDict.new, unistim_port: 0,
#               client_proxy: nil, client_ip: [], num_client_retries: 0,
#               extension: "", licensed: :unknown, sdp: nil, devices: %{},
#               headset_queried: false, num_keys: Mscs.Client.num_keys_default,
#               recovery_time: 500, session_id: nil, get_stat_names_fun: nil,
#               get_stats_fun: nil, get_stats_opts: %{}, audio_open?: false,
#               local_feedback: :none, chrome_56: nil,
#               call_state: @default_call_state, alarm_state: %{}

#     def new, do: %Context{}
#     def new(opts) when is_list(opts), do: struct(new, opts)
#     def new(%Context{} = context) do
#       Context.new(
#         mac: context.mac, ucx_ip: context.ucx_ip, ucx_port: context.ucx_port,
#         client_ip: context.client_ip, serial_no: context.serial_no,
#         unistim_port: context.unistim_port, num_keys: context.num_keys,
#         client_proxy: context.client_proxy, licensed: context.licensed,
#         session_id: context.session_id, chrome_56: context.chrome_56,
#         core_fw_ver: get_fw_version(context))
#     end

#     # The following is an attempt to replace the above new, allowing a more
#     # robust approach of clearing the desired context fields. However, it
#     # does not seem to be working.

#     # @clear_fields [:sip, :num_client_retries, :icon_state, :user_activity_timer,
#     #                :user_activity_timeout, :user_activity_timer_on, :hookswitch,
#     #                :headset, :watchdog_timer, :unistim]

#     # def reset(%Context{} = context) do
#     #   default = %Context{}
#     #   list = for field <- @clear_fields do
#     #     {field, Map.get(default, field)}
#     #   end
#     #   struct context, list
#     # end

#     def get_unistim_pid(r) do
#       r.unistim
#     end
#     def get_fw_version(context) do
#       if context.chrome_56 == false, do: @fw_version_m, else: @fw_version
#     end
#   end
#   #########
#   # API

#   def start_link(%{mac_address: mac} = cx) do
#     # Note, this should be started with Mscs.ClientsSupervisor.start_client/1
#     Logger.debug "client_sm start_link, mac #{mac} #{__MODULE__}"
#     {:ok, pid} = :gen_fsm.start_link __MODULE__, cx, []

#     Mscs.ClientAgent.put mac, pid
#     Logger.debug "ClientSm PID: #{inspect pid}"
#     {:ok, pid}
#   end

#   def unistim(pid, msg) do
#     case Mscs.UnistimRxDecoder.decode(msg) do
#       nil -> nil
#       decoded ->
#         :gen_fsm.send_event(pid, {:unistim, decoded})
#     end
#   end

#   def unistim_packets(pid, msg) do
#     [type, _, len | _] = msg
#     new_msg = Enum.take msg, len + 1
#     unistim(pid, new_msg)
#     remaining = Enum.drop msg, len + 1
#     if Enum.count(remaining) != 0 do
#       unistim_packets(pid, [type] ++ remaining)
#     end
#   end

#   # Receive Unistim message by decoding the message and raising a unistim event
#   def unistim_rx(pid, message) do
#     unistim_packets(pid, message)
#   end

#   def stop(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> stop
#   end
#   def stop(pid), do: :gen_fsm.send_all_state_event(pid, :stop)

#   def status(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> status
#   end
#   def status(pid), do: :gen_fsm.sync_send_all_state_event(pid, :status)

#   def context(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> context
#   end
#   def context(pid), do: :gen_fsm.sync_send_all_state_event(pid, :context)

#   def idle(pid) do
#      :gen_fsm.send_all_state_event(pid, :idle)
#   end

#   def reset(pid) do
#     :gen_fsm.send_all_state_event(pid, :reset)
#   end

#   def render_client(pid) do
#     :gen_fsm.send_all_state_event(pid, :render_client)
#   end

#   def client_message(pid, message) do
#     :gen_fsm.send_event(pid, {:client_message, message})
#   end

#   # these are used for testing only
#   @doc false
#   def put_context(pid, opts),
#     do: :gen_fsm.sync_send_all_state_event(pid, {:put_context, opts})
#   def put_context(pid, state_name, opts),
#     do: :gen_fsm.sync_send_all_state_event(pid, {:put_context, state_name, opts})

#   @doc """
#   Tell the state machine to start connecting with the UCx

#   This message is sent by the channel once we get a join message
#   """
#   def connect(pid) do
#     :gen_fsm.send_event(pid, :connect)
#   end

#   def license_change(pid, settings, count) do
#     :gen_fsm.send_event(pid, {:license_change, settings, count})
#   end

#   def check_license(pid), do: :gen_fsm.send_event(pid, :check_license)

#   def set_client_devices(mac, client_device) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> set_client_devices(client_device)
#   end
#   def set_client_devices(pid, client_device),
#     do: :gen_fsm.send_all_state_event(pid, {:set_client_devices, client_device})

#   def put_client_devices(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> :gen_fsm.send_all_state_event(:put_client_devices)
#   end

#   def send_client_connected(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> send_client_connected
#   end
#   def send_client_connected(pid) when is_pid(pid) do
#     :gen_fsm.send_event(pid, :send_client_connected)
#   end

#   def set_num_keys(mac, num_keys) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> set_num_keys(num_keys)
#   end
#   def set_num_keys(pid, num_keys) when is_pid(pid) do
#     :gen_fsm.send_all_state_event pid, {:set_num_keys, num_keys}
#   end

#   def send_event(mac, event) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> send_event(event)
#   end
#   def send_event(pid, event) do
#     :gen_fsm.send_event(pid, event)
#   end

#   def recovery_complete(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> recovery_complete
#   end

#   def recovery_complete(pid) when is_pid(pid) do
#     :gen_fsm.send_event(pid, :recovery_complete)
#   end

#   def recovery_complete(_) do
#     nil
#   end

#   def session_id(pid) do
#     :gen_fsm.sync_send_all_state_event(pid, :session_id)
#   end

#   def get_stat_names(mac, fun) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> get_stat_names(fun)
#   end
#   def get_stat_names(pid, fun) do
#     :gen_fsm.send_all_state_event(pid, {:get_stat_names, fun})
#   end

#   def get_stats(mac, key, fun) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> get_stats(key, fun)
#   end
#   def get_stats(pid, key, fun) do
#     :gen_fsm.send_all_state_event(pid, {:get_stats, key, fun})
#   end

#   def stop_stats(mac) when is_binary(mac) do
#     ClientAgent.get(mac)
#     |> stop_stats
#   end

#   def stop_stats(pid) when is_pid(pid) do
#     :gen_fsm.send_all_state_event(pid, :stop_stats)
#   end

#   #########
#   # Callbacks

#   def init(%{mac_address: mac} = cx) do
#     :erlang.process_flag(:trap_exit, true)
#     init_random
#     case State.get mac do
#       nil ->
#         Logger.debug "Init with new state"
#         cs_ip = Application.get_env :mscs, :cs_ip, "127.0.0.1"
#         port = Application.get_env :mscs, :ucxport, 7000
#         mac1 = String.to_integer(mac, 16)
#         serial_no = :erlang.binary_to_list <<mac1::48>>

#         context = Context.new(mac: mac, ucx_ip: cs_ip, ucx_port: port, client_ip: cx.client_ip,
#           serial_no: serial_no, client_proxy:  Mscs.ClientProxy.new(id: mac),
#           unistim_port: @unistim_port_base + port_offset(mac), num_keys: cx.num_keys,
#           session_id: cx.session_id, chrome_56: cx.chrome_56, core_fw_ver: Context.get_fw_version(cx))
#           |> init_apb_parms
#           |> update_alarm_state(false)
#         { :ok, :ready, context}
#       %{cx: cx, state: state} ->
#         Logger.debug "Init Recovering State #{state}"
#         context = struct(cx, unistim: nil, headset_queried: false,
#           terminal_id: [0xff, 0xff, 0xff, 0xff],
#           unistim_port: @unistim_port_base + port_offset(mac) )
#         { :ok, :ready, context}
#     end
#   end

#   ##############
#   # ready state

#   def ready(:connect, context) do
#     if ClientManager.get_recovering context.mac do
#       show_initializing_message(context)
#       |> next_state(:recovering, @state_timeout)
#     else
#       do_ready(context)
#     end
#   end

#   def ready(_message, context) do
#     next_state context, :ready, @state_timeout
#   end

#   defp do_ready(context) do
#     context = send_client_devices(context)
#     if Ucx.LicenseManager.licensed?(:MSC) do
#       Logger.debug "ready: licensed! #{context.mac}"
#       license_check(:check_license, context)
#     else
#       Logger.debug "ready: unlicensed! #{context.mac}"

#       # With dev environment, the no license message sometimes gets
#       # lost. Trigger the message after 1 sec resolves the issue
#       :gen_fsm.send_event_after(1000, :show_no_valid_license)

#       set_unlicensed(context)
#       |> show_no_valid_license
#       |> next_state(:license_check, @state_timeout)
#     end
#   end

#   ##############
#   # recovering state

#   def recovering(:recovery_complete, context) do
#     Logger.debug "got complete event"
#     ready(:connect, context)
#   end

#   def recovering(other, context) do
#     Logger.debug "got other: #{inspect other} in recovering state"
#     unless ClientManager.get_recovering context.mac do
#       ready(:connect, context)
#     else
#       next_state context, :recovering, @state_timeout
#     end
#   end

#   ##############
#   # license_check state

#   def license_check(:check_license, context) do
#     license_count = ClientManager.licensed_count
#     Logger.debug ":check_license count: #{license_count}"
#     case ClientManager.check_and_set_licensed(context.mac) do
#       :ok ->
#         start_unistim self
#         ClientManager.delete_unlicensed(context.mac)
#         struct(context, licensed: true)
#         |> handle_license_alarm(:clear_alarm)
#         |> next_state(:initializing, @state_timeout)
#       error ->
#         Logger.info "No license for #{context.mac}, #{inspect error}"
#         set_unlicensed(context)
#         |> show_no_valid_license
#         |> handle_license_alarm(:raise_alarm)
#         |> next_state(:license_check, @license_timeout)
#     end
#   end

#   def license_check(:show_no_valid_license, context) do
#     Logger.debug ":show_no_valid_license for #{context.mac}"
#     context
#     |> show_no_valid_license
#     |> next_state(:license_check, @license_timeout)
#   end
#   def license_check({:license_change, settings, _count}, context) do
#     if settings[:MSC] do
#       license_check(:check_license, context)
#     else
#       next_state context, :license_check, @license_timeout
#     end
#   end
#   def license_check(_event, context) do
#     # Logger.warn "licnese_check event: #{inspect _event}"
#     next_state context, :license_check, @license_timeout
#   end

#   defp show_no_valid_license(context) do
#     context
#     |> client_proxy_write(:basic, :no_license)
#     |> client_proxy_send(:display, :context, text: "&nbsp")
#     |> client_proxy_send(:display, :line, 0, position: 0, text: "No License")
#     |> client_proxy_send(:display, :line, 1, position: 0, text: "&nbsp;")
#     |> client_proxy_send(:display, :line, 2, position: 0, text: "&nbsp;")
#   end

#   defp show_initializing_message(context) do
#     context
#     |> client_proxy_send(:display, :line, 0, position: 0, text: "Initializing...")
#     |> client_proxy_send(:display, :line, 1, position: 0, text: "&nbsp;")
#     |> client_proxy_send(:display, :line, 2, position: 0, text: "&nbsp;")
#   end

#   defp handle_license_alarm(context, raise_clear) do
#     alarm_state = Map.get(context.alarm_state, :no_license)
#     do_license_alarm(context, raise_clear, alarm_state)
#   end

#   defp do_license_alarm(context, :raise_alarm, false) do
#     handle_license_alarm_send(context.mac, :raise_alarm)
#     update_alarm_state(context, true)
#   end
#   defp do_license_alarm(context, :raise_alarm, true), do: context
#   defp do_license_alarm(context, :clear_alarm, true) do
#     handle_license_alarm_send(context.mac, :clear_alarm)
#     update_alarm_state(context, false)
#   end
#   defp do_license_alarm(context, :clear_alarm, false), do: context

#   defp update_alarm_state(context, raise_clear) do
#     struct(context, alarm_state: Map.put(context.alarm_state, :no_license, raise_clear))
#   end

#   ##############
#   # initializing state

#   def initializing(:start_unistim, context) do
#     {cx, state} = start_unistim({:client_rx, ""}, context)
#     next_state cx, state, @state_timeout
#   end

#   def initializing(:timeout, context) do
#     Logger.debug "timeout in initializing state"
#     next_state context, :initializing, @state_timeout
#   end
#   def initializing(message, context) do
#     Logger.debug "Unexpected #{inspect message}"
#     next_state context, :initializing, @state_timeout
#   end

#   ##############
#   # start_unistim state

#   def start_unistim(pid), do: :gen_fsm.send_event(pid, :start_unistim)

#   def start_unistim({:client_rx, _message}, context) do
#     case open_unistim(context) do
#       {:ok, pid} ->
#         Rudp.send pid, Mscs.UnistimTx.resume_connection
#         :erlang.monitor(:process, pid)

#         {struct(context, unistim: pid), :connect_unistim}
#       other ->
#         Logger.error "Failed to open unistim with return code #{inspect other, base: :hex}"
#         {context, :start_unistim}
#     end
#   end

#   def start_unistim(message, context) do
#     Logger.debug "Unexpected #{inspect message} for #{context.mac}"
#     stop(self)
#     next_state context, :start_unistim, @state_timeout
#   end

#   ##############
#   # connect_unistim state

#   def connect_unistim({:unistim, message}, context) do
#     {new_context, next_state} = case message do
#       :query_hardware_id ->
#         Mscs.UnistimTx.send_hardware_id(context.unistim,
#           0, context.serial_no, context.phase, context.terminal_id, 0)
#         # TODO send screen update to client
#         {context, :client_initialize}
#       _ ->
#         Logger.error "connect_unistim: Unrecognized message #{inspect message, base: :hex}"
#         {context, :connect_unistim}
#     end
#     next_state new_context, next_state, @state_timeout
#   end

#   def connect_unistim({:client_message, message}, context) do
#     Logger.debug ":connect_unistim :client_message #{inspect message}"
#     next_state(context, :connect_unistim, @unistim_connect_timeout)
#   end

#   def connect_unistim(:connect, context) do
#     # Logger.debug ":connect_unistim :connect"
#     send_client_devices(context)
#     |> next_state(:connect_unistim, @unistim_connect_timeout)
#   end
#   def connect_unistim(:timeout, context) do
#     # Logger.info ":connect_unistim Timeout: #{context.mac} sending RUDP resume connection"
#     Rudp.send context.unistim, Mscs.UnistimTx.resume_connection
#     next_state context, :connect_unistim, @unistim_connect_timeout
#   end

#   def connect_unistim(:watchdog_timeout, context) do
#     Logger.debug "connect_unistim :watchdog_timeout"
#     handle_watchdog_timeout(context, :connect_unistim)
#     |> next_state(:connect_unistim, @state_timeout)
#   end

#   def connect_unistim(:delayed_start_timeout, context) do
#     Logger.debug "delayed_start_timeout"

#     {:ok, pid} = open_unistim(context)
#     :erlang.monitor(:process, pid)

#     Rudp.send pid, Mscs.UnistimTx.resume_connection

#     struct(context, unistim: pid)
#     |> next_state(:connect_unistim, @state_timeout)
#   end

#   def connect_unistim(message, context) do
#     Logger.debug "Unexpected #{inspect message}"
#     next_state context, :connect_unistim, @state_timeout
#   end

#   ##############
#   # client_initialize state

#   @vol_keys ~w(vol-up vol-low)

#   @fixed_keys ~w(release mute hold handsfree headset soft_message cancel expand
#                  record directory portal history settings favorites web btmarrow
#                  leftarrow rightarrow toparrow midbut)

#   def client_initialize(:connect, context) do
#     send_client_devices(context)
#     |> next_state(:client_initialize, @state_timeout)
#   end

#   def client_initialize({:client_message, message}, context) do
#     case message do
#       {:watchdog_ack, _key} ->
#          # Logger.debug "Got watch_dog ack from client, #{inspect key}"
#          struct(context, num_client_retries: nil)
#       {:headset_status, _status} ->
#         log_trace(context, :client_initialize, :client_message, message)
#         handle_client_message(context, message)
#       {:handset_status, _status} ->
#         log_trace(context, :client_initialize, :client_message, message)
#         handle_client_message(context, message)
#       other ->
#         Logger.debug "Unexpected message: #{inspect other}"
#         context
#     end
#     |> next_state(:client_initialize, @state_timeout)
#   end
#   def client_initialize({:unistim, msg}, context) do
#     state = :client_initialize
#     if not Mscs.ClientSm.Utils.ignore_message?(@ignore_unistim_logging_msgs, msg) do
#       # Logger.debug "client_initialize: #{inspect msg, base: :hex}"
#       log_trace(context, state, :unistim, msg)
#     end
#     {new_context, next_state} = case msg do
#       {:read_dram_data, _data} ->
#         Logger.debug "Transitioning to :active state! #{context.mac}"
#         {client_proxy_write(context, :basic, :connected, success: true), :active}
#       {:assign_terminal_id, id} ->
#         feat_status_lamp_ctrl(context)
#         {struct(context, terminal_id: id), state}
#       :query_attributes ->
#         # get the phone attributes
#         # Logger.debug "client_initialize: unistim_send - device_type: #{context.device_type}, "
#         #               <> "name: #{context.device_name} num_keys #{context.num_keys}"
#         num_keys = min(context.num_keys, @base_prgm_keys)
#         # num_keys = @base_prgm_keys
#         Mscs.UnistimTx.send_phone_attributes(context.unistim,
#            Mscs.Device.get_device_properties(context.device_type, num_keys), context.terminal_id, 0)
#         send_aem_update(context)
#         {context, state}
#       :query_phone_type ->
#         Logger.debug "Sending phone type #{inspect context.device_type, base: :hex}"
#         {send_unistim(context, {:phone_type, context.device_type}), state}
#       :query_firmware ->
#         {send_unistim(context, {:firmware_version, "#{context.core_fw_ver}"}), state}
#       :query_hookswitch ->
#         {send_unistim(context, {:hookswitch_status, context.hookswitch}), state}
#       # :query_headset ->
#       #   send_unistim(context, {:headset_status, context.headset})
#       {:dset_unregistered, data} ->
#         Logger.debug "dset unregistered in client_initialize and data is : #{inspect data, base: :hex}"
#         {context, state}
#       _->
#         {handle_common_unistim(context, :client_initialize, msg), state}
#     end

#     next_state new_context, next_state, @state_timeout
#   end

#   def client_initialize(:watchdog_timeout, context) do
#     Logger.error "client_initialize watchdog timeout"
#     handle_watchdog_timeout(context, :client_initialize)
#     |> next_state(:client_initialize, @state_timeout)
#   end

#   def client_initialize(:timeout, context) do
# #   Logger.error "Skipping timeout"
#     next_state context, :client_initialize, @state_timeout
#   end
#   def client_initialize(message, context) do
#     Logger.debug "Unexpected #{inspect message}"
#     next_state context, :client_initialize, @state_timeout
#   end

#   ##############
#   # active state

#   def active({:client_message, message}, context) do
#     # Logger.debug "active: :client_message #{inspect message}"
#     if not Mscs.ClientSm.Utils.ignore_message?(@ignore_client_msgs, message) do
#       log_trace(context, :active, :client_message, message)
#     end
#     handle_client_message(context, message)
#     |> next_state(:active, @state_timeout)
#   end

#   def active({:unistim, message}, context) do
#     if not Mscs.ClientSm.Utils.ignore_message?(@ignore_unistim_logging_msgs, message) do
#       # Logger.debug "active: #{inspect message, base: :hex}"
#       log_trace(context, :active, :unistim, message)
#     end
#     handle_common_unistim(context, :unistim, message)
#     |> next_state(:active, @state_timeout)
#   end
#   def active(:watchdog_timeout, context) do
#     Logger.debug "active :watchdog_timeout mac: #{context.mac}"
#     handle_watchdog_timeout(context, :active)
#     |> next_state(:active, @state_timeout)
#   end
#   def active(:timeout, context) do
#     # Logger.debug "active :timeout"
#     next_state context, :active, @state_timeout
#   end
#   def active(:connect, context) do
#     send_client_devices(context)
#     |> next_state(:active, @state_timeout)
#   end
#   def active({:license_change, [MSC: false], _}, context) do
#     Logger.debug "idling SM. No license"
#     idle(self)
#     delete_licensed(context)
#     |> next_state(:active, @state_timeout)
#   end
#   def active(:send_client_connected, context) do
#     client_proxy_write(context, :basic, :connected, success: true)
#     |> next_state(:active, @state_timeout)
#   end

#   # Uncomment this for testing purposes
#   # def active(:crash, _context) do
#   #   :ok = true
#   # end

#   def active(message, context) do
#     Logger.debug "Unexpected #{inspect message}"
#     next_state context, :active, @state_timeout
#   end


#   ##############
#   # Event handlers

#   def terminate(reason, _context) do
#     Logger.info  "#{__MODULE__} terminate/2  reason: #{inspect reason}"
#   end

#   def terminate(reason, state_name, context) do
#     cancel_watchdog context.watchdog_timer
#     ClientAgent.delete context.mac
#     ClientManager.delete_licensed(context.mac)
#     ClientManager.delete_unlicensed(context.mac)
#     remove_system_client context.mac
#     SystemAgent.delete :extensions, context.extension
#     ClientManager.put_recovering context.mac, context.recovery_time, &__MODULE__.recovery_complete/1
#     ClientManager.notify_unlicensed
#     Mscs.ClientProxy.write context.client_proxy, :network, :hard_reset, []

#     Logger.info "terminate in state: #{inspect state_name}, reason: #{inspect reason}"
#     :ok
#   end

#   @doc """
#   Render the client state

#   Used when the browser is reloaded after an active connection
#   """
#   def handle_event(:render_client, state, context) do
#     # need a list of stuff to send to the client.
#     Logger.debug "refreshing the client #{context.mac}"
#     {new_context, new_state} =
#       if context.licensed != true do
#         {show_no_valid_license(context), state}
#       else
#         if context.audio_open? do
#           Logger.debug "Refresh page during an active call. Forcing a soft reset"
#           handle_soft_reset(context)
#         else
#           send_client_devices(context, context.devices)
#           Mscs.ClientProxy.refresh_client(context.client_proxy)
#           {send_client_query_headset(context), state}
#         end
#         # query apb values from DB and send to client
#         {send_client_apb_parms(context, context.mac, context.client_ip, @headset_apb), state}
#         {send_client_apb_parms(context, context.mac, context.client_ip, @handsfree_apb), state}
#       end
#     next_state(new_context, new_state, @state_timeout)
#   end

#   def handle_event(:stop, _state, context) do
#     cancel_watchdog context.watchdog_timer
#     State.delete context
#     Logger.debug "Stopping ClientSm mac: #{context.mac}"
#     {:stop, :normal, context}
#   end

#   def handle_event({:status, caller}, state, context) do
#     Logger.info "status: #{inspect context}"
#     send caller, {:status_result, {state, context}}
#     next_state context, state, @state_timeout
#   end

#   def handle_event(:reset, _state, context) do
#     close_unistim context
#     # context1 = Context.reset(context)
#     context1 = Context.new(context)
#     {:ok, pid} = open_unistim(context1)
#     :erlang.monitor(:process, pid)

#     Rudp.send pid, Mscs.UnistimTx.resume_connection
#     next_state(struct(context1, unistim: pid), :connect_unistim, @state_timeout)
#   end

#   def handle_event({:reset_watchdog, timeout}, state, context) do
#     next_state reset_watchdog(context, timeout), state, @state_timeout
#   end

#   def handle_event(:idle, _state, context) do
#     close_unistim context
#     cancel_watchdog context.watchdog_timer

#     context1 =
#     struct(context, client_proxy: Mscs.ClientProxy.new(id: context.mac))
#     |> Context.new

#     license_check(:check_license, context1)
#   end

#   def handle_event({:set_client_devices, devices}, state, context) do
#     struct(context, devices: devices)
#     |> send_client_devices(devices)
#     |> send_client_query_headset
#     |> next_state(state, @state_timeout)
#   end

#   def handle_event(:put_client_devices, state, context) do
#     context
#     |> send_client_devices(context.devices)
#     |> next_state(state, @state_timeout)
#   end

#   def handle_event({:set_num_keys, num_keys}, state, context) do
#     old_num_keys = context.num_keys
#     base_num_keys = min(num_keys, @base_prgm_keys)
#     # base_num_keys = @base_prgm_keys
#     Mscs.UnistimTx.send_phone_attributes(context.unistim,
#         Mscs.Device.get_device_properties(context.device_type,
#           base_num_keys), context.terminal_id, 0)
#     context
#     |> update_proxy_keys(base_num_keys)
#     |> struct(num_keys: num_keys)
#     # |> send_aem_list
#     |> send_aem_update(old_num_keys)
#     |> next_state(state, @state_timeout)
#   end
#   def handle_event({:get_stat_names, fun}, state, context) do
#     client_proxy_write(context, :webrtc, :get_stat_names)
#     %Context{context | get_stat_names_fun: fun}
#     |> next_state(state, @state_timeout)
#   end
#   def handle_event({:get_stats, opts, fun}, state, context) do
#     handle_get_stats(context, opts, fun)
#     |> next_state(state, @state_timeout)
#   end

#   def handle_event(:stop_stats, state, context) do
#     case context.get_stats_opts do
#       %{timer_ref: ref} when not is_nil(ref) ->
#         cancel_timer ref
#       _ -> nil
#     end
#     %Context{context | get_stats_opts: %{}}
#     |> next_state(state, @state_timeout)
#   end

#   defp handle_get_stats(context) do
#     handle_get_stats context, context.get_stats_opts, context.get_stats_fun
#   end
#   defp handle_get_stats(context, key, fun) when is_binary(key) do
#     client_proxy_write(context, :webrtc, :get_stats, key: key)
#     %Context{context | get_stats_fun: fun}
#   end
#   defp handle_get_stats(context, opts, fun) do
#     opts = Enum.into opts, %{}
#     context = %Context{context | get_stats_fun: fun, get_stats_opts: opts}
#     case opts do
#       %{key: key, interval: _} = opts ->
#         if context.audio_open? do
#           fields = Map.get(opts, :fields, [])
#           client_proxy_write(context, :webrtc, :get_stats, key: key, fields: fields)
#           |> start_stats_interval
#         else
#           context
#         end
#       %{key: key, fields: fields} ->
#         client_proxy_write(context, :webrtc, :get_stats, key: key, fields: fields)
#       %{key: key} ->
#         client_proxy_write(context, :webrtc, :get_stats, key: key)
#       _opts ->
#         client_proxy_write(context, :webrtc, :get_stats, key: "all")
#     end

#   end

#   defp pause_stats_interval(%{get_stats_opts: stats_opts} = context) do
#     case stats_opts do
#       %{timer_ref: ref} = opts when not is_nil(ref) ->
#         opts = Map.put opts, :timer_ref, nil
#         cancel_watchdog(ref)
#         struct(context, get_stats_opts: opts)
#       _ ->
#         context
#     end
#     |> struct(audio_open?: false)
#   end

#   defp start_stats_interval(%{get_stats_opts: stats_opts} = context) do
#     case stats_opts do
#       %{interval: interval} = opts ->
#         if opts[:timer_ref], do: cancel_watchdog(opts[:timer_ref])
#         ref = round(interval * 1000)
#         |> :erlang.start_timer(self(), :stats_timeout)
#         struct(context, get_stats_opts: Map.put(opts, :timer_ref, ref))
#       _ ->
#         context
#     end
#     |> struct(audio_open?: true)
#   end

#   def handle_sync_event(:status, _from, state, context) do
#     reply context, {state, context}, state
#   end
#   def handle_sync_event(:context, _from, state, context) do
#     reply context, context, state
#   end
#   def handle_sync_event(:session_id, _from, state, context) do
#     reply context, context.session_id, state
#   end
#   def handle_sync_event({:put_context, opts}, _from, state, context) do
#     context = struct(context, opts)
#     reply context, context, state
#   end
#   def handle_sync_event({:put_context, state_name, opts}, _from, _state, context) do
#     context = struct(context, opts)
#     reply context, context, state_name
#   end

#   def handle_info({:timeout, _ref, :user_activity_timeout}, state, context) do
#     send_unistim(context, :user_activity_timeout)
#     |> struct(user_activity_timeout: nil)
#     |> next_state(state, @state_timeout)
#   end

#   def handle_info({:DOWN, _, :process, _, _}, :ready, cx) do
#     set_unlicensed(cx)
#     |> next_state(:ready, @state_timeout)
#   end
#   def handle_info({:DOWN, p1, :process, p2, p3}, state, cx) do
#     Logger.info "DOWN message in state #{inspect state} p1: #{inspect p1}, p2: #{inspect p2}, p3: #{inspect p3}"
#     Logger.debug "licensed: #{inspect cx.licensed}"
#     if cx.licensed == true do
#       {new_context, new_state} = handle_soft_reset(cx)
#       next_state new_context, new_state, @state_timeout
#     else
#       next_state cx, :license_check, @license_timeout
#     end
#   end
#   def handle_info({:timeout, _, :stats_timeout}, state, context) do
#     handle_get_stats(context)
#     |> next_state(state, @state_timeout)
#   end
#   def handle_info(message, state, cx) do
#     Logger.debug "Unexpected message: #{inspect message}"
#     next_state cx, state, @state_timeout
#   end

#   ##############
#   # Private functions

#   defp handle_client_message(context, message) do
#     case message do
#       {:stat_names_resp, msg} ->
#         case context.get_stat_names_fun do
#           nil -> context
#           fun ->
#             fun.({context.mac, msg})
#             struct context, get_stat_names_fun: nil
#         end
#       {:stats_resp, msg} ->
#         for item <- msg do
#           str = Map.to_list(item)
#           |> Enum.map(fn({k,v}) -> "#{k}: #{v}" end)
#           |> Enum.join(", ")
#           Logger.info "#{context.mac} get_stats: " <> str
#         end
#         case context.get_stats_fun do
#           nil -> context
#           fun ->
#             fun.({context.mac, msg})
#             context
#         end
#       {:watchdog_ack, _key} ->
#          # Logger.debug "Got watch_dog ack from client, #{inspect key}"
#          struct(context, num_client_retries: nil)
#       {:btn_press, "pk-" <> key} ->
#          # Logger.debug "Got btn_press, pk-#{key}"
#          handle_prog_key_press(context, String.to_integer(key))
#          #send_unistim context, {:program_key, String.to_integer(key)}
#       {:btn_press, "soft-" <> key} ->
#         send_unistim(context, {:soft_key, String.to_integer(key)})
#         |> start_useraction_timer
#       {:btn_press, "dp-*"}  ->
#         handle_dp_press(context, 0xa)
#       {:btn_press, "dp-#"}  ->
#         handle_dp_press(context, 0xb)
#       {:btn_press, "dp-" <> key}  ->
#         handle_dp_press(context, String.to_integer(key))
#       {:vbtn_press, "fk-" <> key, apb, current_vol} when key in @vol_keys ->
#         handle_stream_based_volume(context, key, apb, current_vol)
#       {:btn_press, "fk-" <> key} when key in @fixed_keys ->
#         send_unistim(context, String.to_atom(key <> "_key"))
#         |> start_useraction_timer
#       {:btn_press, key} ->
#         Logger.error "Ignoring unsupported key: #{inspect key}"
#         context
#       {:headset_status, status} ->
#         handle_client_headset_status(context, status)
#       {:handset_status, status} ->
#         send_unistim context, {:handset_status, status}
#       {:apb_default_rx_volume, ceiling, floor, active_apb, apb_def_rx_vol, vol_range} ->
#         data = ceiling <<< 7 ||| floor <<< 6 ||| active_apb &&& 0x1f
#         send_unistim context, {:apb_default_rx_volume, data, apb_def_rx_vol, vol_range}
#       {:audio_mgr_attrib, _data} ->
#         # Logger.debug "audio_mgr_attrib: #{inspect data}"
#         context
#       {:webrtc_offer, message} ->
#         sdp = message["sdp"]
#         |> Sdp.parse

#         struct(context, sdp: create_sdp(context))
#         |> unistim_tx_ice_dtls(:ice_parameter_upload, sdp, :a, :"ice-ufrag")
#         |> unistim_tx_ice_dtls(:ice_parameter_upload, sdp, :a, :"ice-pwd")
#         |> unistim_tx_ice_dtls(:ice_parameter_upload, sdp, :a, :candidate)
#         |> unistim_tx_ice_dtls(:dtls_parameter_upload, sdp, :a, :connection)
#         |> unistim_tx_ice_dtls(:dtls_parameter_upload, sdp, :a, :setup)
#         |> unistim_tx_ice_dtls(:dtls_parameter_upload, sdp, :a, :fingerprint)
#         |> send_unistim({:open_audio_status, 0x0})

#       {:webrtc_candidate, message} ->
#         candidate = case message["candidate"] do
#           empty when empty == "" or is_nil(empty) -> "candidate:"
#           other -> other
#         end
#         send_unistim(context, {:ice_parameter_upload, candidate})
#     end
#   end

#   defp unistim_tx_ice_dtls(context, msg_type, sdp, key, field) do
#     Sdp.render_field(sdp, key, field)
#     |> Enum.reduce(context, fn(item, cx) ->
#       send_unistim cx, {msg_type, item}
#     end)
#   end

#   defp handle_client_headset_status(%{headset_queried: true, headset: status} = context, status), do: context
#   defp handle_client_headset_status(%{headset_queried: true} = context, status) do
#     message = if status do
#       :headset_connected
#       {:headset_status, true}
#     else
#       :headset_disconnected
#       {:headset_status, false}
#     end
#     struct(context, headset: status)
#     |> send_unistim(message)
#   end
#   defp handle_client_headset_status(context, status) do
#     struct(context, headset_queried: true, headset: status)
#     |>send_unistim({:headset_status, status})
#   end

#   defp handle_common_unistim(context, state, message) do
#     case message do

#       # messages to ignore
#       {:aem_keyindm_driver_opt, _, _} -> context
#       {:aem_dispm_cont_lvl_set, _, _} -> context
#       :query_user_pin                 -> context
#       {:clear_field, _}               -> context
#       {:arrow, 0}                     -> context
#       {:dsp_gain, _}                  -> context
#       :accessory_sync_update          -> context
#       {:repeat_timer_download, _list} -> context

#       {:key_options, data} ->
#         local = case data &&& 0x60 do
#           0x20 -> :click
#           0x40 -> :dtmf
#           _ -> :none
#         end

#         struct(context, local_feedback: local)
#         |> client_proxy_send(:key, :local_feedback, option: local)

#       :soft_reset ->
#         Logger.debug "Received soft_reset for #{context.mac}"
#         idle(self)
#         Proxy.refresh_client(context.client_proxy)
#         |> update_proxy_cx(context)
#       :hard_reset ->
#         Logger.debug "Received hard_reset for #{context.mac}"
#         stop(self)
#         context
#       { :hook_switch_key, :release } ->
#         send_unistim(context, :onhook)
#       :query_media_ip_address ->
#         send_unistim(context, {:media_ip_address, context.client_ip})
#       # the rx_stream_id and tx_stream_id can have values of 0 or 0xFF, 0xFF is to close all streams
#       {:open_audio_stream, data} ->
#         # Logger.info "open_audio_stream data #{inspect data}"
#         handle_open_audio_stream(context, data)
#         |> start_stats_interval
#       {:close_audio_stream, rx_stream_id, tx_stream_id} ->
#         handle_close_audio_stream(context, rx_stream_id, tx_stream_id)
#         |> pause_stats_interval
#       {:connect_transducer, tx_enable, rx_enable, pair_id, apb_number, stream_list} ->
#         Enum.reduce stream_list, context, fn(stream_id, acc) ->
#           client_proxy_send acc, :audio, :connect_transducer, stream_id, [
#             tx_enable: tx_enable, rx_enable: rx_enable, pair_id: pair_id,
#             apb_number: apb_number
#           ]
#         end
#       {:alerting_tone_configuration, transducer_routing, warbler_select,
#                                      cadence_select, tone_volume_steps} ->
#         client_proxy_send context, :audio, :alerting_tone_configuration,
#            Enum.zip([:transducer_routing, :warbler_select, :cadence_select, :tone_volume_steps],
#                     [transducer_routing, warbler_select, cadence_select, tone_volume_steps])
#       {:transducer_tone_volume, tone_level, tone_id} ->
#         client_proxy_send context, :audio, :transducer_tone_volume, tone_id,
#           tone_level: tone_level
#       {:special_tone_configuration, transducer_routing, tone_volume_steps, special_tone_select} ->
#         client_proxy_send context, :audio, :special_tone_configuration,
#            Enum.zip([:transducer_routing, :tone_volume_steps, :special_tone_select],
#                     [transducer_routing, tone_volume_steps, special_tone_select])
#       {:paging_tone_cadence_download, paging_tone_select_1, on_time_1, off_time_1,
#                                       paging_tone_select_2, on_time_2, off_time_2} ->
#         client_proxy_send context, :audio, :paging_tone_cadence_download,
#            Enum.zip([:paging_tone_select_1, :on_time_1, :off_time_1,
#                      :paging_tone_select_2, :on_time_2, :off_time_2],
#                     [paging_tone_select_1, on_time_1, off_time_1,
#                     paging_tone_select_2, on_time_2, off_time_2])
#       {:paging_tone_configuration, transducer_routing, cadence_select, tone_volume_steps} ->
#         client_proxy_send context, :audio, :paging_tone_configuration,
#            Enum.zip([:transducer_routing, :cadence_select, :tone_volume_steps],
#                     [transducer_routing, cadence_select, tone_volume_steps])
#       {:mute_unmute, rx_tx, mute, stream_id, _data} ->
#         client_proxy_send context, :audio, :mute_unmute, stream_id, [rx_tx: rx_tx, mute: mute]
#       {:transducer_tone_on, attenuated, tone_id} ->
#         client_proxy_send context, :audio, :transducer_tone_on, tone_id, attenuated: attenuated
#       {:transducer_tone_off, tone_id} ->
#         Proxy.delete(context.client_proxy, :audio, :transducer_tone_on, tone_id)
#         |> update_proxy_cx(context)
#         |> client_proxy_send(:audio, :transducer_tone_off, tone_id)
#       {:stream_based_tone_frequency_download, tone_id, list} ->
#         client_proxy_send context, :audio, :stream_based_tone_frequency_download, tone_id,
#           frequencies: get_frequencies(list)
#       {:stream_based_tone_cadence_download, one_shot, tone_id, list} ->
#         client_proxy_send context, :audio, :stream_based_tone_cadence_download, tone_id,
#           [one_shot: one_shot, list: list]
#       {:stream_based_tone_on, mute, rx_tx, tone_id, stream_id, volume_level } ->
#         client_proxy_send context, :audio, :stream_based_tone_on, stream_id,
#           [mute: mute, rx_tx: rx_tx, tone_id: tone_id, volume_level: volume_level]
#       {:stream_based_tone_off, rx_tx, tone_id, stream_id} ->
#         Proxy.delete(context.client_proxy, :audio, :stream_based_tone_on, stream_id)
#         |> update_proxy_cx(context)
#         |> client_proxy_send(:audio, :stream_based_tone_off, stream_id, [
#           tone_id: tone_id, rx_tx: rx_tx])
#       {:useract_timer_download, timeout} ->
#         struct(context, user_activity_timeout: timeout * 200)
#       :useract_timer_on ->
#         struct(context, user_activity_timer_on: true)
#         |> start_useraction_timer
#       :useract_timer_off ->
#         struct(context, user_activity_timer_on: false)
#         |> stop_useraction_timer
#       # {:repeat_timer_download, _list} ->
#       #   context
#       {:time_and_date_format, value} ->
#         msg = [
#           time: value &&& 0x10, time_format: time_format(value &&& 0x3),
#           date: value &&& 0x20, date_format: date_format(value &&& 0xc)
#         ]
#         client_proxy_send(context, :display, :time_and_date_format, msg)
#       {:time_and_date_download, data} ->
#         client_proxy_send context, :display, :time_and_date_download,
#           Enum.zip([:year, :month, :day, :hour, :minute, :second], data)
#       # {:dsp_gain, _values} ->
#       #   context
#       # {:key_options, _value} ->
#       #   context
#       {:contrast, _value} ->
#         # ignore this message since it does not make sense for a soft client
#         context
#       {:set_recovery_time, d1, d2} ->
#         time = round((d1 + :random.uniform * (d2 - d1)) * 1000)
#         Logger.debug "setting recovery time for min: #{d1} and max: #{d2} to #{time/1000}"
#         %Context{context | recovery_time: time}
#       # :query_user_pin ->

#       #   context
#       {:led_update, operation, action} ->
#         operation = "fk-" <> Atom.to_string operation
#         action = Atom.to_string action
#         client_proxy_send(context, :key, :led_update, operation, state: action)
#       {:icon_update, id, state, cadence} ->
#         key = "pk-" <> Integer.to_string id
#         data = Enum.zip [:state, :cadence], [state, cadence]
#         context
#         |> handle_icon_update(id, state, cadence)
#         |> client_proxy_send(:key, :icon_update, key, data)
#       {:status_bar_icon_update, id, state, cadence} ->
#         key = "disp-" <> Integer.to_string id
#         data = Enum.zip [:state, :cadence], [state, cadence]
#         client_proxy_send(context, :display, :status_bar_icon_update, key, data)
#       # {:clear_field, _string} ->
#       #   context
#       # {:arrow, _val} ->
#       #   context
#       {:reset_watchdog, timeout} ->
#         # Logger.debug "reset_watchdog: value #{inspect timeout, base: :hex}"
#         if state == :active and context.licensed != true do
#           Logger.debug "Found unlicensed ClientSm in Active State."
#           idle(self)
#         end
#         reset_watchdog(context, timeout)
#       {:display_write, :line, line_number, position, highlight, text} ->
#         context
#         |> client_proxy_send(:display, :line, line_number, position: position,
#                               highlight: highlight, text: text)
#       {:display_write, :soft_key, list} ->
#         Enum.with_index(list)
#         |> Enum.reduce(context, fn({text, num}, cx) ->
#           client_proxy_send(cx, :display, :soft_key, num, text: encoded_empty_string(text))
#         end)
#       {:display_write, :context, text } ->
#         client_proxy_send context, :display, :context, text: text
#       {:display_write, :pk, key, text} ->
# #       Logger.debug "display_write: key #{key} text #{text}"
#         context
#         |> client_proxy_send(:display, :pk, key, text: encoded_empty_string(text))

#       {:aem_dispm_soft_label_key, dev, [offset | text]} ->
#         # Logger.debug "aem_dispm_soft_label_key: device #{dev} offset #{offset} text #{text}"

#         client_proxy_send(context, :display, :pk, aem_dev_offset_to_key_num(dev, offset),
#           text: List.to_string(text) |> encoded_empty_string)

#       {:aem_keyindm_icon_update, dev, offset, state, cadence} ->
#         # Logger.debug "aem_keyindm_icon_update: dev #{dev} offset #{offset} state #{state} cadence: #{cadence}"
#         key = aem_dev_offset_to_key_num dev, offset
#         key = "pk-" <> Integer.to_string key
#         client_proxy_send context, :key, :icon_update, key, state: state, cadence: cadence

#       {:aem_dispm_page_mode_set, device, data} ->
#         Logger.debug "aem_dispm_page_mode_set: device #{device} data #{data}"
#         context

#       {:query_audio_manager, flags, default_rx_vol_id} ->
#         Mscs.ClientProxy.write(context.client_proxy, :audio, :query_audio_manager, flags: flags,
#                                default_rx_vol_id: default_rx_vol_id)
#         context
#       {:audio_manager_options, _data} ->
#         #Logger.debug "audio_manager_options: #{data}"
#         #Mscs.ClientProxy.write(context.client_proxy, :audio, :audio_manager_options, data: data)
#         context
#       {:ice_parameter_download, data} ->
#         data = List.to_string data

#         if String.starts_with? data, "candidate:" do
#           Mscs.ClientProxy.write context.client_proxy, :webrtc, :candidate,
#             candidate: %{candidate: data, sdpMLineIndex: 0, sdpMid: "audio"}
#           context
#         else
#           struct(context, sdp: Sdp.add_field(context.sdp, :a, data))
#         end
#       {:dtls_parameter_download, data} ->
#         data = List.to_string data

#         sdp = context.sdp
#         |> Sdp.replace_field(:a, data)

#         if String.starts_with? data, "fingerprint:" do
#           # we are done, send the offer
#           Mscs.ClientProxy.write context.client_proxy, :webrtc, :answer,
#             name: "asterisk", answer: %{type: "answer", sdp: Sdp.render(sdp)}
#         end
#         struct(context, sdp: sdp)
#       :query_acc_list ->
#         send_aem_list(context)
#       {:aem_basm_fw_version, device} ->
#         handle_aem_fw_version(context, device)
#       {:aem_basm_hwid, device} ->
#         handle_aem_hwid(context, device)
#       {:set_default_character_table, data} ->
#         Logger.debug "set_default_character_table - #{inspect data}"
#         context
#       msg ->
#         Logger.warn "No handler for UNISTIM message: #{inspect msg}"
#         context
#     end
#   end

#   defp open_unistim(%{unistim: nil} = context) do
#     ip = context.ucx_ip
#     port = context.ucx_port
#     Mscs.ClientsSupervisor.open_unistim_socket(ip, port, context.unistim_port,
#       fn(pid, message) -> unistim_rx(pid, message) end, self)
#   end
#   defp open_unistim(context) do
#     Logger.error "Ignoring open_unistim. Already open. pid: #{inspect context.unistim}, mac: #{context.mac}"
#     context
#   end

#   defp create_sdp(context) do
#     ui = :erlang.unique_integer |> abs |> Integer.to_string

#     [
#       "a=fmtp:126 0-16",
#       "a=rtpmap:126 telephone-event/8000",
#       "a=rtpmap:0 PCMU/8000",
#       "m=audio 13938 RTP/SAVPF 0 126",
#       "t=0 0",
#       "c=IN IP4 #{context.ucx_ip}",
#       "s=Asterisk PBX 11.20.0",
#       "o=root #{ui} #{ui} IN IP4 #{context.ucx_ip}",
#       "v=0",
#     ]
#     |> add_rtcp_mux(context)
#     |> Enum.reverse
#     |> Enum.join("\r\n")
#     |> Sdp.parse
#   end

#   defp add_rtcp_mux(sdp, %{chrome_56: false}), do: ["a=rtcp-mux\r\n" | sdp]
#   defp add_rtcp_mux([first | tail], _), do: [first <> "\r\n" | tail]

#   def send_unistim(context, message) do
#     # Logger.debug "send_unistim: message #{inspect message, base: :hex}"
#     log_trace(context, "       ", :send_unistim, message)
#     Mscs.UnistimTx.send_message(context.unistim, message, context.terminal_id, 0)
#     context
#   end

#   defp handle_open_audio_stream(context, data) do
#     rx_stream_id = Keyword.get(data, :rx_stream_id, 0)
#     tx_stream_id = Keyword.get(data, :tx_stream_id, 0)
#     local = Keyword.get(data, :local, [])
#     local_ip = context.client_ip
#     local_rtp_port = Keyword.get(local, :rtp_port, 0)
#     local_rtcp_port = Keyword.get(local, :rtcp_port, 0)
#     far_end = Keyword.get(data, :far_end, [])
#     far_end_ip = Keyword.get(far_end, :ip_address, [])
#     far_end_rtp_port = Keyword.get(far_end, :rtp_port, 0)
#     far_end_rtcp_port = Keyword.get(far_end, :rtcp_port, 0)

#     client_proxy_send(context, :audio, :open_audio_stream,
#       rx_stream_id: rx_stream_id, tx_stream_id: tx_stream_id,
#       local_ip: local_ip, local_rtp_port: local_rtp_port, local_rtcp_port: local_rtcp_port,
#       far_end_ip: far_end_ip, far_end_rtp_port: far_end_rtp_port,
#       far_end_rtcp_port: far_end_rtcp_port)
#   end

#   defp handle_close_audio_stream(context, rx_stream_id, tx_stream_id) do
#     # TODO : close RTP packet stream to dest_ip:dest_port
#     Proxy.delete(context.client_proxy, :audio, :open_audio_stream) # , {rx_stream_id, tx_stream_id})
#         |> update_proxy_cx(context)
#         |> client_proxy_send(:audio, :close_audio_stream, # {rx_stream_id, tx_stream_id},
#             rx_stream_id: rx_stream_id, tx_stream_id: tx_stream_id)
#   end

#   defp handle_watchdog_timeout(context, _state) do
#     Logger.error "watchdog timeout: #{context.mac}"
#     idle(self)
#     struct(context, watchdog_timer: nil)
#   end

#   def reset_watchdog(%{watchdog_timer: watchdog_timer} = context, timeout) do
#     cancel_watchdog(watchdog_timer)
#     timeout_value = timeout * @watchdog_timer_scaler
#     unless timer_ref = :gen_fsm.send_event_after(timeout_value, :watchdog_timeout),
#       do: Logger.error "reset_watchdog: send_event_after failed"
#    Mscs.ClientProxy.send context.client_proxy, :network, :reset_watchdog, timer: timeout_value
#    struct(context, watchdog_timer: timer_ref)
#    |> handle_client_watchdog
#   end

#   def cancel_watchdog(nil), do: nil
#   def cancel_watchdog(%{watchdog_timer: watchdog_timer} = context) do
#     cancel_watchdog(watchdog_timer)
#     struct(context, watchdog_timer: nil)
#   end
#   def cancel_watchdog(watchdog_timer), do: :gen_fsm.cancel_timer(watchdog_timer)
#   def cancel_timer(timer_ref), do: :gen_fsm.cancel_timer(timer_ref)

#   defp handle_client_watchdog(%{num_client_retries: nil} = context) do
#     struct(context, num_client_retries: 0)
#   end
#   defp handle_client_watchdog(%{num_client_retries: count} = context)
#       when count >= @max_client_retries do
#     Logger.warn "Client watchdog retry count: #{inspect count}, stopping ClientSm #{context.mac}"
#     Mscs.ClientProxy.write context.client_proxy, :network, :hard_reset, []
#     stop(self)
#     struct(context, num_client_retries: 0)
#   end
#   defp handle_client_watchdog(%{num_client_retries: count} = context) do
#     Logger.debug "Client watchdog retry count: #{inspect count}"
#     if context.call_state[:active] do
#       Logger.error "Client watchdog retry during active call"
#       struct(context, num_client_retries: 0)
#     else
#       struct(context, num_client_retries: count + 1)
#     end
#   end

#   defp client_proxy_send(context, category, field, opts) do
#     context.client_proxy
#     |> Proxy.put_and_send(category, field, opts)
#     |> update_proxy_cx(context)
#   end
#   defp client_proxy_send(context, category, field, key, opts) do
#     context.client_proxy
#     |> Proxy.put_and_send(category, field, key, opts)
#     |> update_proxy_cx(context)
#   end

#   defp client_proxy_write(context, category, field, opts \\ []) do
#     Proxy.write context.client_proxy, category, field, opts
#     context
#   end

#   defp update_proxy_cx(proxy, context) do
#     struct context, client_proxy: proxy
#   end


#   def next_state({state_data, state_name}) do
#     next_state(state_data, state_name)
#   end
#   def next_state({state_data, state_name}, timeout) do
#     next_state(state_data, state_name, timeout)
#   end
#   def next_state(state_data, state_name) do
#     State.put state_data, state_name
#     # debug(state_data, state_name)
#     # Logger.warn "next_state"
#     {:next_state,  state_name, state_data}
#   end

#   def next_state(state_data, state_name, timeout) do
#     State.put state_data, state_name
#     # debug(state_data, state_name)
#     # Logger.warn "next_state"
#     {:next_state,  state_name, state_data, timeout}
#   end

#   def reply(state_data, response, state_name) do
#     State.put state_data, state_name
#     {:reply, response, state_name, state_data}
#   end

#   def reply(state_data, response, state_name, timeout) do
#     State.put state_data, state_name
#     {:reply, response, state_name, state_data, timeout}
#   end


#   defp handle_soft_reset(context) do
#     close_unistim(context)
#     Mscs.ClientProxy.send context.client_proxy, :network, :soft_reset, []

#     delay = get_soft_reset_delay
#     Logger.debug fn -> "handle_soft_reset using delayed timer: #{delay}, mac: #{context.mac}" end

#     :gen_fsm.send_event_after(delay, :delayed_start_timeout)
#     {Context.new(context), :connect_unistim}
#   end

#   defp get_soft_reset_delay do
#     count = ClientAgent.get |> Enum.count
#     base = Application.get_env(:mscs, :delay_start_base_ms, 1000)
#     per_client = Application.get_env(:mscs, :delay_start_per_client_ms, 100)

#     round(:random.uniform * count * per_client) + base
#   end

#   def close_unistim(%{unistim: nil} = context), do: context
#   def close_unistim(context) do
#     cancel_watchdog context.watchdog_timer
#     Logger.debug "closing unistim connection, mac: #{context.mac}, pid: #{inspect context.unistim}"
#     Rudp.close context.unistim
#     struct(context, unistim: nil)
#   end

#   # user activity timeout handlers
#   defp start_useraction_timer(%{user_activity_timer_on: false} = context), do: context
#   defp start_useraction_timer(context) do
#     stop_useraction_timer(context)
#     |> _start_useraction_timer
#   end
#   defp _start_useraction_timer(nil), do: throw({:error, "nil context"})
#   defp _start_useraction_timer(context) do
#     _start_useraction_timer(context, context.user_activity_timeout)
#   end
#   # ignore the start without timeout download
#   defp _start_useraction_timer(context, 0), do: context
#   defp _start_useraction_timer(context, nil), do: context
#   defp _start_useraction_timer(context, timeout) do
#     timer_ref = :erlang.start_timer timeout, self(), :user_activity_timeout
#     struct(context, user_activity_timer: timer_ref)
#   end

#   defp stop_useraction_timer(context) do
#     if context.user_activity_timer, do:
#       :erlang.cancel_timer(context.user_activity_timer)
#     struct(context, user_activity_timer: nil)
#   end

#   # function to turn off feature status lamp (blue color) on soft phone
#   defp feat_status_lamp_ctrl(context) do
#     operation = "fk-feat_status"
#     action = "off"
#     client_proxy_send(context, :key, :led_update, operation, state: action)
#   end

#   defp time_format(0),   do: "12-hour"
#   defp time_format(1),   do: "french"
#   defp time_format(2),   do: "24-hour"
#   defp time_format(_),   do: ""
#   defp date_format(0),   do: "day-first"
#   defp date_format(0x4), do: "month-first"
#   defp date_format(0x8), do: "numeric-standard"
#   defp date_format(0xc), do: "numeric-inverse"

#   def set_licensed(context) do
#     ClientManager.delete_unlicensed(context.mac)
#     ClientManager.put_licensed(context.mac)
#     struct(context, licensed: true)
#   end

#   def set_unlicensed(context) do
#     ClientManager.delete_licensed(context.mac)
#     ClientManager.put_unlicensed(context.mac)
#     struct(context, licensed: false)
#   end

#   defp delete_licensed(%{licensed: true} = context) do
#     ClientManager.delete_licensed(context.mac)
#     struct(context, licensed: :unknown)
#   end
#   defp delete_licensed(%{licensed: false} = context) do
#     ClientManager.delete_unlicensed(context.mac)
#     struct(context, licensed: :unknown)
#   end
#   defp delete_licensed(context) do
#     context
#   end

#   defp get_frequencies(list) do
#     for [f1, f2] <- Enum.chunk(list, 2), do: get_frequency(f1, f2)
#   end

#   defp get_frequency(freq1, freq2) do
#     (freq1 * 8000 + (freq2 * div(8000,256)) + 128) |> div(256)
#   end

#   defp send_client_devices(context) do
#     ip_addr = Helpers.to_integer context.client_ip
#     context
#     |> send_client_devices(Mscs.ClientController.get_devices(context.mac, ip_addr))
#   end

#   @dev_ids [:handsfree_input_id, :handsfree_output_id, :headset_input_id, :headset_output_id]
#   defp send_client_devices(context, devices) do
#     Logger.debug "devices: #{inspect devices}"
#     msg = for key <- @dev_ids, do: {key, Map.get(devices, key) || ""}
#     Logger.debug "devices: #{inspect msg}"
#     client_proxy_send(context, :audio, :client_devices, msg)
#   end

#   defp send_client_query_headset(context) do
#     Mscs.ClientProxy.write(context.client_proxy, :audio, :query_audio_manager, flags: 0x80)
#     context
#   end

#   @doc """
#   Calculate and save a new unistim port offset.

#   Each client uses a unique port number starting from port
#   @unistim_port_base (18000). This routine get an new offset that
#   is added to 18000.

#   The offset is calculated sequentially, based on the size of the
#   list used to store the allocated ports. To handle the scenario
#   when clients are deleted and removed from the list, a free_ports
#   list is also maintained. When a client is deleted, the offset
#   assigned to that client is added to the free_ports list.

#   So, to get a new port offset, we check the free_ports list first.
#   An idled port number is popped from that list and used if available.
#   Otherwise, a new offset is calculated based on the size of the list.

#   Note that all this logic is handled in an Agent.update fn to avoid
#   concurrency issues.
#   """
#   def port_offset(mac) do
#     Mscs.SystemAgent.update fn(state) ->
#       case Dict.get(state.clients, mac) do
#         nil ->
#           case state.free_ports do
#             [port | t] ->
#               add_offset(state, mac, port)
#               |> struct(free_ports: t)
#             _ ->
#               add_offset(state, mac, Dict.size(state.clients))
#           end
#         _ -> state
#       end
#     end
#     Mscs.SystemAgent.get(:clients, mac)
#   end
#   defp add_offset(state, mac, num) do
#     clients = Dict.put(state.clients, mac, num)
#     struct(state, clients: clients)
#   end

#   @doc """
#   Remove a client from the clients data in the System Agent.

#   As well as removing the client entry, the port offset allocated
#   for that client is moved to the free_ports list, for allocation
#   of the next registering client.
#   """
#   def remove_system_client(mac) do
#     Mscs.SystemAgent.update fn(state) ->
#       case Dict.get state.clients, mac do
#         nil -> state
#         port ->
#           state
#           |> struct(free_ports: [port | state.free_ports])
#           |> struct(clients: Dict.delete(state.clients, mac))
#       end
#     end
#   end

#   defp init_random do
#     :random.seed :erlang.unique_integer([:positive]),
#       :erlang.unique_integer([:positive]),
#       (:erlang.monotonic_time |> abs)
#   end

#   @trace_ignore [{:watchdog_ack, nil}]

#   defp log_trace(context, _state, _type, message) when message in @trace_ignore,
#     do: context
#   defp log_trace(context, state, type,  message) do
#     Logger.debug fn -> "#{state} #{context.mac}: #{type} #{inspect message}" end
#     context
#   end

#   defp init_apb_parms(context) do
#     send_client_apb_parms(context, context.mac, context.client_ip, @headset_apb)
#     send_client_apb_parms(context, context.mac, context.client_ip, @handsfree_apb)
#   end

#   defp send_client_apb_parms(context, mac, ip_addr, apb) do
#     get_apb_current_volume(mac, ip_addr, apb)
#     |> case do
#       nil ->
#         Logger.warn "send_client_apb_parms: No record found"
#       current_volume ->
#         Logger.debug "refreshing the client, apb: #{apb},  current_volume #{inspect current_volume}"
#         client_proxy_write(context, :audio, :set_apb_rx_volume_levels,
#                                apb: apb, rx_vol_level: current_volume)
#     end
#     context
#   end

#   defp set_apb_parms(mac, ip_addr, apb_parm) do
#     ip_addr = Helpers.to_integer ip_addr
#     Mscs.ApbController.update_apb(mac, ip_addr, apb_parm)
#   end

#   defp get_apb_current_volume(mac, ip_addr, apb) do
#     ip_addr = Helpers.to_integer ip_addr
#     Mscs.ApbController.get_apb_parm(mac, ip_addr, apb)
#     |> case do
#       nil -> nil
#       apb_parm -> apb_parm.current_volume
#     end
#   end

#   defp handle_stream_based_volume(context, _key, apb, current_vol) do
#     # volume settings for audio and audio-stream
#     # volume level will be sent using Set APB’s Rx Volume Levels (21 hex/5), during initialization.
#     # The volume settings will have a default for handsfree (3) and headset (2) APBs (handset is not used)
#     # When user changes the volume setting, value will be updated in DB through Apb controller
#     # client also keeps track of volume changes.
#     Logger.debug "handle_stream_based_volume: apb: #{apb} current_vol: #{current_vol}"
#     set_apb_parms(context.mac, context.client_ip, %{apb_number: apb, current_volume: current_vol})
#     context
#   end

#   ################
#   # expansion keys

#   defp send_aem_update(%{num_keys: num_keys} = context) when (num_keys > 24 and num_keys <= 120) do
#     send_unistim context, {:send_aem_update, true, @aem_device_1}
#   end

#   defp send_aem_update(context), do: context

#   defp send_aem_update(%{num_keys: num_keys} = context, present_num_keys) do
#     # Logger.debug "send_aem_update: present_num_keys #{present_num_keys} num_keys #{num_keys}"
#     send_ready_disconnect_msg context, num_keys, present_num_keys
#   end

#   defp send_aem_update(_keys, context), do: context

#   defp send_ready_disconnect_msg(context, new, old) do
#     {add_remove?, range} = get_aem_update_params(new, old)
#     # Logger.warn "================> send_ready_disconnect_msg: new: #{new}, old: #{old}, range; #{inspect range}, add?: #{add_remove?}"
#     for n <- range do
#       send_unistim context, {:send_aem_update, add_remove?, n}
#       :timer.sleep(10)
#     end
#     context
#   end

#   defp get_aem_update_params(new, old) do
#     {new > old, _get_aem_update_params(get_aem_num_devs(new), get_aem_num_devs(old))}
#   end
#   defp _get_aem_update_params(new, old) when new > old do
#     (old + @aem_device_1)..(new + @aem_device_1 - 1)
#   end
#   defp _get_aem_update_params(new, old) when new < old do
#     (new + @aem_device_1)..(old + @aem_device_1 - 1)
#   end
#   defp _get_aem_update_params(_new, _old), do: []

#   defp get_aem_num_devs(num_keys) when num_keys <= 24 or num_keys > 120, do: 0
#   defp get_aem_num_devs(num_keys), do: div(num_keys - 1, 24)

#   @aem_list [9,10,10,10,11,10,12,10]
#   defp send_aem_list(%{num_keys: num_keys} = context) when num_keys > 24 and num_keys <= 120 do
#     aem_count = div(num_keys - 1, 24)
#     send_unistim context, {:send_aem_list, Enum.slice(@aem_list, 0, aem_count * 2)}
#   end
#   defp send_aem_list(context) do
#     send_unistim context, {:send_aem_list, []}
#   end


#   defp handle_aem_hwid(context, device) do
#     send_unistim context, {:send_aem_hwid, device, '00000' ++ [0]}
#   end

#   defp handle_aem_fw_version(context, device) do
#     send_unistim context, {:send_aem_fwversion, device, @aem_fw_version}
#   end

#   defp handle_prog_key_press(context, key) when key >= 24 and key < 48 do
#     send_unistim context, {:send_aem_key_press, @aem_device_1, key - 24}
#   end
#   defp handle_prog_key_press(context, key) when key >= 48 and key < 72 do
#     send_unistim context, {:send_aem_key_press, @aem_device_2, key - 48}
#   end
#   defp handle_prog_key_press(context, key) when key >= 72 and key < 96 do
#     send_unistim context, {:send_aem_key_press, @aem_device_3, key - 72}
#   end
#   defp handle_prog_key_press(context, key) when key >= 96 and key < 120 do
#     send_unistim context, {:send_aem_key_press, @aem_device_4, key - 96}
#   end
#   defp handle_prog_key_press(context, key) when key >= 0 and key < 24 do
#     send_unistim context, {:program_key, key}
#   end
#   defp handle_prog_key_press(context, key) do
#     Logger.warn "Invalid key #{key} for mac: #{context.mac}"
#     context
#   end

#   defp aem_dev_offset_to_key_num(device, offset) do
#     (device - 8) * 24 + offset
#   end

#   defp icon_state(0, 1), do: :idle
#   defp icon_state(4, 1), do: :active
#   defp icon_state(6, 1), do: :hold
#   defp icon_state(10, 1), do: :dialtone
#   defp icon_state(_state, _cadence), do: nil

#   defp handle_icon_update(%{call_state: cs} = context, id, st, cad) when idle_icon_state?(st, cad) do
#     cs = if id > cs[:pk_max] do
#       put_in(cs, [:pk_max], id)
#     else
#       cs
#     end
#     |> update_in([:pk_state], &(Map.delete(&1, id)))

#     if cs[:pk_state] == %{} do
#       # no active calls
#       struct(context, call_state: Enum.into([end_call: false, active: false], cs))
#       |> client_proxy_write(:call_state, :end_call, state: false)
#       |> client_proxy_write(:call_state, :active, state: false)
#     else
#       # still some active calls
#       struct(context, call_state: cs)
#     end
#   end
#   # call_state: %{end_call: false, active: false, pk_max: 0, pk_state: %{}}
#   defp handle_icon_update(%{call_state: %{pk_max: pk_max} = cs} = context, id, st, cad)
#          when dialtone_icon_state?(st, cad) and id <= pk_max do
#     cs = cs
#     |> put_in([:end_call], true)
#     |> put_in([:pk_state, id], icon_state(st, cad))
#     struct(context, call_state: cs)
#     |> client_proxy_write(:call_state, :end_call, state: true)
#     |> client_proxy_write(:call_state, :dialtone, state: true)
#   end
#   defp handle_icon_update(%{call_state: %{pk_max: pk_max} = cs} = context, id, st, cad)
#          when hold_icon_state?(st, cad) and id <= pk_max do
#     cs = cs
#     |> put_in([:end_call], false)
#     |> put_in([:pk_state, id], icon_state(st, cad))
#     struct(context, call_state: cs)
#     |> client_proxy_write(:call_state, :end_call, state: false)
#   end
#   defp handle_icon_update(%{call_state: %{pk_max: pk_max} = cs} = context, id, st, cad)
#          when active_icon_state?(st, cad) and id <= pk_max do
#     cs = cs
#     |> put_in([:end_call], true)
#     |> put_in([:active], true)
#     |> put_in([:pk_state, id], icon_state(st, cad))
#     struct(context, call_state: cs)
#     |> client_proxy_write(:call_state, :end_call, state: true)
#     |> client_proxy_write(:call_state, :active, state: true)
#   end
#   defp handle_icon_update(context, _id, _st, _cad), do: context

#   defp update_proxy_keys(%{num_keys: old_keys} = context, new_keys) when new_keys < old_keys do
#     range = new_keys..(old_keys - 1)

#     Enum.reduce(range, context.client_proxy, fn(key, proxy) ->
#       proxy
#       |> Proxy.put_and_send(:key, :icon_update, "pk-#{key}", [state: 0, cadence: 0])
#       |> Proxy.write(:key, :disable, key: "pk-#{key}")
#       |> Proxy.delete(:display, :pk, key)
#       |> Proxy.delete(:key, :icon_update, "pk-#{key}")
#     end)
#     |> update_proxy_cx(context)
#   end
#   defp update_proxy_keys(%{num_keys: old_keys} = context, new_keys) when new_keys > old_keys do
#     range = old_keys..(new_keys - 1)
#     Enum.reduce(range, context.client_proxy, fn(key, proxy) ->
#       proxy
#       |> Proxy.write(:key, :enable, key: "pk-#{key}")
#     end)
#     |> update_proxy_cx(context)
#   end
#   defp update_proxy_keys(context, _), do: context


#   defp handle_dp_press(context, key) do
#     context
#     |> send_unistim({:key_press, key})
#     |> start_useraction_timer
#   end

#   def handle_license_alarm_send(mac, raise_clear) do
#     if raise_clear == :raise_alarm do
#        {event_id, severity, description, action, acknowledge} =
#          {@no_license, :critical, "WebRTC Client #{mac} does not have license",
#           "Add WebRTC Client License on UCx", :acknowledge_no}
#        Mscs.MscsAlarmManager.set(:no_client_license, mac, "Client License", description,
#                                  ucx_event: [event_id, severity, action, acknowledge])
#     else
#        {event_id, severity, description, acknowledge} =
#           {@no_license, :info, "WebRTC Client #{mac} has license", :acknowledge_no}
#        Mscs.MscsAlarmManager.clear(:no_client_license, mac, ucx_event: [event_id, severity, description, acknowledge])
#     end
#   end
# end
