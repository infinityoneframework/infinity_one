defmodule UccWebrtcWeb.WebrtcChannel do
  use UcxUccWeb, :channel
  use UccLogger

  alias UccWebrtc.ClientDevice
  alias UcxUcc.UccPubSub
  alias UccChatWeb.RebelChannel.Client
  alias UcxUccWeb.Endpoint
  alias Rebel.SweetAlert
  alias UccWebrtWeb.FlexBar.Tab.MembersList
  alias UccWebrtcWeb.VideoView
  alias UcxUcc.Accounts

  import Rebel.Core
  import Rebel.Query

  require Logger

  @device_fields [
    :handsfree_input_id,
    :handsfree_output_id,
    :headset_input_id,
    :headset_output_id,
    :video_input_id
  ]

  intercept [
    "webrtc:leave"
  ]

  def device_manager_init(socket, _payload) do
    case exec_js(socket, "window.UcxUcc.DeviceManager.installed_devices") do
      {:ok, installed_devices} ->
        socket =
          ClientDevice.get_by(user_id: socket.assigns.user_id)
          |> set_client_devices(installed_devices, socket)
        # exec_js(socket, "window.WebRTC.start();")
        socket
      {:error, error} ->
        Client.toastr!(socket, :error, "Problem getting installed devices: #{inspect error}")
        socket
    end
    |> noreply
  end

  def on_connect(socket) do
    # called from the User socket.
    case ClientDevice.get_by user_id: socket.assigns.user_id do
      nil ->
        exec_js socket, "window.UccChat.devices = {}"
        socket
      device ->
        str =
          Enum.map(@device_fields, fn field ->
            "#{field}: '#{Map.get(device, field, "")}'"
          end)
          |> Enum.join(", ")

        exec_js socket, "window.UcxUcc.devices = {" <> str <> "}"
        socket
    end
  end

  def join("webrtc:user-" <> _name, payload, socket) do
    if authorized?(payload) do
      if socket.assigns[:state] do
        {:error, %{reason: "internal error"}}
      else
        :erlang.process_flag(:trap_exit, true)
        # Process.send_after self(), :after_join, 1000
        {:ok, assign(socket, :state, %{})}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_out("webrtc:leave" = ev, payload, socket) do
    trace ev, payload
    trace ev, socket.assigns
    push socket, ev, payload
    unless payload[:dest] do
      do_broadcast socket, socket.assigns.state["otherName"], "leave", %{dest: true}
    end
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    # UccPubSub.unsubscribe "user:" <> socket.assigns.user_id
    :ok
  end

  ##########
  # Incoming message handlers

  def handle_in(ev = "webrtc:user-" <> nm, %{"type" => "offer", "name" => name,
      "offer" => offer} = msg, socket) do
    trace ev, msg
    Logger.debug "Sending offer to #{name}"
    String.split(offer["sdp"], "\r\n")
    |> Enum.each(&(Logger.debug &1))
    # Logger.debug "offer #{name} #{inspect offer}"
    case socket.assigns[:state] do
      nil -> socket
      data ->
        socket
        |> assign(:state, Map.put(data, "otherName", name))
        |> do_broadcast(name, "offer", %{type: "offer", offer: msg["offer"], name: nm})
        |> ucc_broadcast("webrtc:offer", %{offer: offer, name: name, from: nm})
    end
    |> noreply
  end

  def handle_in(ev = "webrtc:user-" <> _nm, %{"type" => "answer", "name" => name,
      "answer" => answer} = msg, socket) do
    trace ev, msg
    Logger.debug "Sending answer to #{name}"
    # Logger.debug "answer #{name} #{inspect answer}"
    String.split(answer["sdp"], "\r\n")
    |> Enum.each(&(Logger.debug &1))

    socket =
      case socket.assigns[:state] do
        nil -> socket
        data ->
          socket
          |> assign(:state, Map.put(data, "otherName", name))
          |> do_broadcast(name, "answer", %{type: "answer", answer: msg["answer"]})
          |> ucc_broadcast("webrtc:answer", %{anwser: answer, name: name})
      end
    {:noreply, socket}
  end

  def handle_in(ev = "webrtc:user-" <> _nm, %{"type" => "leave", "name" => name} =
      msg, socket) do
    trace ev, msg
    Logger.debug "Disconnecting from  #{name}"
    case socket.assigns[:state] do
      nil -> socket
      data ->
        socket
        |> assign(:state, Map.put(data, "otherName", nil))
        |> do_broadcast(name, "leave", %{type: "leave"})
        |> ucc_broadcast("webrtc:leave", %{name: name})
    end
    {:noreply, socket}
  end

  def handle_in(ev = "webrtc:user-" <> _nm, %{"type" => "candidate",
      "name" => name, "candidate" => candidate} = msg, socket) do
    trace ev, msg
    Logger.debug "Sending candidate to #{name}: #{inspect candidate}"
    socket =
      socket
      |> do_broadcast(name, "candidate", %{candidate: msg["candidate"]})
      |> ucc_broadcast("webrtc:candiate", %{candidate: candidate, name: name})
    {:noreply, socket}
  end

  def handle_in(ev = "webrtc:user-" <> nm, msg, socket) do
    trace ev, msg
    type = msg["type"]
    Logger.debug "name: #{nm}, unknown type: #{type}, msg: #{inspect msg}"
    socket = do_broadcast socket, nm, "error", %{type: "error", message: "Unrecognized command: " <> type}
    {:noreply, socket}
  end

  def handle_in(topic, data, socket) do
    Logger.error "Unknown -- topic: #{topic}, data: #{inspect data}"
    {:noreply, socket}
  end

  defp do_broadcast(socket, name, message, data) do
    UcxUccWeb.Endpoint.broadcast "webrtc:user-" <> name, "webrtc:" <> message, data
    socket
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  #################
  # Callbacks

  def incoming_video_call(payload, socket) do
    trace "incoming_video_call", payload
    trace "incoming_video_call", socket.assigns
    title = "Direct video call from #{payload[:username]}"
    icon = "videocam"
    SweetAlert.swal_modal socket, ~s(<i class="icon-#{icon} alert-icon success-color"></i>#{title}), "Do you want to accept?", nil,
      [html: true, showCancelButton: true, closeOnConfirm: true, closeOnCancel: true],
      confirm: fn result ->
        Logger.warn "sweet confirmed! #{inspect result}"
        open_my_video_tab(socket, payload)
        Endpoint.broadcast "user:" <>  payload[:from], "webrtc:confirmed_video_call",
          %{user_id: socket.assigns.user_id}
      end,
      cancel: fn result ->
        Endpoint.broadcast "user:" <>  payload[:from], "webrtc:declined_video_call",
          %{user_id: socket.assigns.user_id}
        Logger.warn "sweet canceled! result: #{inspect result}"
      end

    {:noreply, socket}
  end

  # def handle_info(:after_join, socket) do
  #   trace "after_join", socket.assigns
  #   #exec_js socket, "window.WebRTC.start();"
  #   {:noreply, socket}
  # end

  def open_my_video_tab(socket, payload) do
    trace "payload", payload
    trace "assigns", socket.assigns

    socket
    |> MembersList.open_destination_video(socket.assigns.user_id, payload[:from])
    |> open_remote_video_item(payload[:from])
  end

  def confirmed_video_call(payload, socket) do
    trace "confirmed_video_call payload", payload
    trace "confirmed_video_call assign", socket.assigns
    exec_js socket, "window.WebRTC.call('#{payload.user_id}');"
    open_remote_video_item socket, payload.user_id
    {:noreply, socket}
  end

  defp open_remote_video_item(socket, user_id) do
    trace "open_remote_video_item", %{user_id: user_id}
    user = Accounts.get_user user_id

    html = Phoenix.View.render_to_string VideoView, "remote_video_item.html",
      item: %{connected: true, username: user.username}

    socket
    |> insert(html, append: ".videos")

    spawn fn ->
      Process.sleep 3000
      js = ~s{$('.videos .video-item[data-username="#{user.username}"] video')[0].srcObject = window.WebRTC.remoteVideo.srcObject}
      exec_js socket, js
    end
    socket
  end

  def declined_video_call(payload, socket) do
    trace "declined_video_call payload", payload
    trace "declined_video_call assigns", socket.assigns

    {:noreply, socket}
  end

  def webrtc_answer(event, payload, socket) do
    Logger.warn "..."
    trace event, payload, inspect(socket.assigns)
    socket
  end

  def webrtc_leave(event, payload, socket) do
    Logger.warn "..."
    trace event, payload, inspect(socket.assigns)
    socket
  end

  # defp ucc_broadcast(%{assigns: assigns} = socket, topic) do
  #   UccPubSub.broadcast "user:" <> assigns.user_id, topic, %{}
  #   socket
  # end

  defp ucc_broadcast(%{assigns: assigns} = socket, topic, payload) do
    UccPubSub.broadcast "user:" <> assigns.user_id, topic, payload
    socket
  end

  defp set_client_devices(nil, installed_devices, socket) do
    case ClientDevice.create %{user_id: socket.assigns.user_id, ip_addr: socket.assigns.ip_address} do
      {:ok, client_device} ->
        client_device
      {:error, changeset} ->
        errors = UcxUccWeb.Utils.format_errors changeset
        Client.toastr(socket, :error, "Problem creating ClientDevice: #{errors}")
        nil
    end
    |> set_client_devices(installed_devices, socket)
  end
  defp set_client_devices(client_device, installed_devices, socket) do
    str =
      client_device
      |> get_selected_devices(installed_devices)
      |> Enum.map(fn {field, value} ->
        "#{field}: '#{value}'"
      end)
      |> Enum.join(", ")

    exec_js socket, "window.UcxUcc.DeviceManager.devices = {" <> str <> "}"
    socket
  end

  # client_device  && present in installed_devices -> use client device
  # no client_device use default device [field]
  defp get_selected_devices(client_device, installed_devices) do
    client_device = client_device || %{}
    for device_field <- @device_fields, into: %{} do
      client_value = Map.get(client_device, device_field, "")
      device = validate_device(device_field, client_value,
        installed_devices[client_value], installed_devices)
      {device_field, device}
    end
  end

  defp validate_device(field, client_value, installed_value, installed_devices)
  defp validate_device(field, _, nil, installed_devices) do
    default_device(field, installed_devices)
  end
  defp validate_device(_field, client_value, _, _) do
    client_value
  end

  defp default_device(:video_input_id, devices) do
    first_device :video, devices
  end
  defp default_device(:handsfree_input_id, %{"default" => _}) do
    "default"
  end
  defp default_device(:handsfree_input_id, devices) do
    first_device :input, devices
  end
  defp default_device(:handsfree_output_id, %{"default" => _}) do
    "default"
  end
  defp default_device(:handsfree_output_id, devices) do
    first_device :output, devices
  end
  defp default_device(_, _) do
    ""
  end

  defp first_device(kind, devices) when is_atom(kind) do
    kind |> kind() |> first_device(devices)
  end

  defp first_device(kind, devices) do
    case Enum.find(devices, & elem(&1, 1)["kind"] == kind) do
      nil -> ""
      {device, _} -> device
    end
  end

  defp kind(:input), do: "audioinput"
  defp kind(:output), do: "audiooutput"
  defp kind(:video), do: "videoinput"


end
