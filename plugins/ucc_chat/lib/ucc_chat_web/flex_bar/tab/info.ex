defmodule UccChatWeb.FlexBar.Tab.Info do
  use UccChatWeb.FlexBar.Helpers
  use UccLogger

  alias UccChat.Channel
  alias UcxUcc.TabBar.Tab
  alias UcxUcc.UccPubSub

  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel direct],
      "info",
      ~g"Info",
      "icon-info-circled",
      View,
      "channel_settings.html",
      10,
      [
        model: UccChat.Channel,
        prefix: "channel"
      ]
    )
  end

  def args(socket, {user_id, channel_id, _, _,}, params) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id) |> set_private()
    changeset = Channel.change channel
    editing = to_existing_atom(params["editing"])

    # assigns =
    #   socket
    #   |> Rebel.get_assigns()
    #   |> Map.put(:channel, channel)
    #   |> Map.put(:resource_key, :channel)

    # Rebel.put_assigns(socket, assigns)

    {[
      channel: settings_form_fields(channel, user_id),
      current_user: current_user,
      changeset: changeset,
      editing: editing,
      channel_type: channel.type], socket}
  end

  def notify_update_success(socket, tab, sender, %{toggle: _} = opts) do
    trace "notify_update_success toggle", {tab, sender}
    trace "assigns", socket.assigns

    params = %{channel_id: opts.resource.id, field: socket.assigns.toggle_field}
    Logger.debug "params: " <> inspect(params)
    broadcast socket, "room:update", params
  end

  def notify_update_success(socket, _tab, _sender, opts) do
    trace "notify_update_success", opts.resource_params

    field =
      opts.resource_params
      |> Enum.reject(fn {k, v} -> v == "on" or k == "id" end)
      |> Enum.map(fn {k, v} -> {to_existing_atom(k), v} end)
      |> hd

    params = %{channel_id: opts.resource.id, field: field}

    broadcast(socket, "room:update", params)
  end

  def flex_form_toggle(socket, _sender, resource, "#channel_archived" = id, true = val) do
    Logger.debug "channel_archived true"
    {_params, socket} = set_toggle_field socket, id, val
    case Channel.archive resource, socket.assigns.user_id do
      {:ok, _}            -> {:ok, socket}
      {:error, changeset} ->
        Logger.error "changeset: #{inspect changeset.errors}"
        {:error, changeset, socket}
    end
  end

  def flex_form_toggle(socket, _sender, resource, "#channel_archived" = id, false = val) do
    Logger.debug "channel_archived false"
    {_params, socket} = set_toggle_field socket, id, val
    case Channel.unarchive resource, socket.assigns.user_id do
      {:ok, _}            -> {:ok, socket}
      {:error, changeset} ->
        Logger.warn "changeset: #{inspect changeset.errors}"
        {:error, changeset, socket}
    end
  end

  def flex_form_toggle(socket, _sender, resource, id, val) do
    trace "flex_form_toggle", socket.assigns, inspect({id, val, resource})
    {params, socket} = set_toggle_field socket, id, val

    case Channel.update resource, params do
      {:ok, _} -> {:ok, socket}
      {:error, changeset} -> {:error, changeset, socket}
    end
  end

  defp set_toggle_field(socket, id, val) do
    field = translate_field id
    value = translate_value field, val
    socket = Phoenix.Socket.assign socket, :toggle_field, {field, value}
    {%{field => value}, socket}
  end

  def translate_field("#channel_private"), do: :type
  def translate_field("#channel_" <> str), do: to_existing_atom(str)

  def translate_value(:type, true), do: 1
  def translate_value(:type, _),    do: 0
  def translate_value(_, val),      do: val

  defp to_existing_atom(nil), do: nil
  defp to_existing_atom(atom) when is_atom(atom), do: atom
  defp to_existing_atom(value), do: String.to_existing_atom(value)

  defp set_private(%{type: 1} = channel), do: struct(channel, private: true)
  defp set_private(channel), do: struct(channel, private: false)

  defp broadcast(socket, event, payload) do
    UccPubSub.broadcast "user:" <> socket.assigns.user_id, event, payload
    socket
  end
end

