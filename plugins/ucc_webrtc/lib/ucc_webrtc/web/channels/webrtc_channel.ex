defmodule UccWebrtc.Web.WebrtcChannel do
  use UcxUcc.Web, :channel

  require Logger

  # def join("webrtc:lobby", payload, socket) do
  #   if authorized?(payload) do
  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "unauthorized"}}
  #   end
  # end

  def join("webrtc:" <> event, payload, socket) do
    Logger.warn inspect({"webrtc: " <> event, payload, socket})
    {:ok, socket}
  end

  #############################
  # Outgoing message handlers

  def handle_out(event, payload, socket) do
    Logger.info "handle_out topic: #{event}, payload: #{inspect payload}"
    {:reply, {:ok, payload}, socket}
  end

  #############################
  # Incoming message handlers

  def handle_in("client:" <> current_user, %{"type" => "offer",
    "user_id" => user_id, "offer" => offer} = msg, socket) do
    Logger.debug "Sending offer to #{user_id}"

    offer["sdp"]
    |> String.split("\r\n")
    |> Enum.each(&(Logger.debug &1))
    # Logger.debug "offer #{name} #{inspect offer}"
    # case State.get nm do
    #   nil -> :ok
    #   data ->
    #     State.put nm, Map.put(data, "otherName", name)
    #     do_broadcast name, "offer", %{type: "offer", offer: msg["offer"], name: nm}
    # end
    do_broadcast user_id, "offer", %{type: "offer", offer: offer,
      user_id: current_user}
    {:noreply, assign(socket, :webrtc_dest, user_id)}
  end

  def handle_in("client:" <> current_user, %{"type" => "answer",
    "user_id" => user_id, "answer" => answer} = msg, socket) do
    Logger.debug "Sending answer to #{user_id}"
    # Logger.debug "answer #{name} #{inspect answer}"
    answer["sdp"]
    |> String.split("\r\n")
    |> Enum.each(&(Logger.debug &1))

    # case State.get nm do
    #   nil -> :ok
    #   data ->
    #     State.put nm, Map.put(data, "otherName", name)
    #     do_broadcast name, "answer", %{type: "answer", answer: msg["answer"]}
    # end
    do_broadcast user_id, "answer", %{type: "answer", answer: answer,
      user_id: current_user}
    {:noreply, assign(socket, :webrtc_dest, user_id)}
  end

  def handle_in("client:" <> _current_user, %{"type" => "leave",
    "user_id" => user_id} = msg, socket) do
    Logger.debug "Disconnecting from  #{user_id}"

    # case State.get nm do
    #   nil -> :ok
    #   data ->
    #     State.put nm, Map.put(data, "otherName", nil)
    #     do_broadcast name, "leave", %{type: "leave"}
    # end
    do_broadcast user_id, "leave", %{type: "leave"}
    {:noreply, assign(socket, :webrtc_dest, nil)}
  end

  def handle_in("client:" <> current_user, %{"type" => "candidate",
      "user_id" => user_id, "candidate" => candidate} = msg, socket) do

    Logger.debug "Sending candidate to #{user_id}: #{inspect candidate}"

    do_broadcast user_id, "candidate", %{candidate: msg["candidate"]}
    {:noreply, socket}
  end

  def handle_in("client:" <> current_user, msg, socket) do
    type = msg["type"]
    Logger.debug "name: #{current_user}, unknown type: #{type}, msg: #{inspect msg}"
    do_broadcast current_user, "error", %{type: "error",
      message: "Unrecognized command: " <> type}
    {:noreply, socket}
  end

  def handle_in(topic, data, socket) do
    Logger.error "Unknown -- topic: #{topic}, data: #{inspect data}"
    {:noreply, socket}
  end

  defp do_broadcast(name, message, data) do
    UcxUcc.Web.Endpoint.broadcast "webrtc:" <> name, "webrtc:" <> message, data
  end

  defp do_broadcast(socket, name, message, data) do
    broadcast socket, "webrtc:" <> name, "webrtc:" <> message, data
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
