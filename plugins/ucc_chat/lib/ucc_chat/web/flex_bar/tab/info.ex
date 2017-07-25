defmodule UccChat.Web.FlexBar.Tab.Info do
  use UccChat.Web.FlexBar.Helpers
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
      10)
  end

  def args(socket, user_id, channel_id, _, params) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id) |> set_private()
    changeset = Channel.change channel
    editing = to_existing_atom(params["editing"])

    assigns =
      socket
      |> Rebel.get_assigns()
      |> Map.put(:channel, channel)
      |> Map.put(:resource_key, :channel)

    Rebel.put_assigns(socket, assigns)

    {[
      channel: settings_form_fields(channel, user_id),
      current_user: current_user,
      changeset: changeset,
      editing: editing,
      channel_type: channel.type], socket}
  end

  def notify_update_success(socket, tab, sender, %{toggle: _} = opts) do
    trace "notify_update_success toggle", {tab, sender}

    params = %{channel_id: opts.resource.id, field: socket.assigns.toggle_field}
    broadcast socket, "room:update", params
  end

  def notify_update_success(socket, tab, sender, opts) do
    trace "notify_update_success", opts.resource_params

    field =
      opts.resource_params
      |> Enum.reject(fn {_, v} -> v == "on" end)
      |> Enum.map(fn {k, v} -> {to_existing_atom(k), v} end)
      |> hd

    params = %{channel_id: opts.resource.id, field: field}
    socket
    |> broadcast("room:update", params)
  end

  def flex_form_toggle(socket, sender, resource, id, val) do
    trace "flex_form_toggle", socket.assigns, inspect({id, val, resource})
    field = translate_field id
    value = translate_value field, val
    params = %{field => value}
    socket = Phoenix.Socket.assign socket, :toggle_field, {field, value}

    case Channel.update resource, params do
      {:ok, _} -> {:ok, socket}
      {:error, changeset} -> {:error, changeset, socket}
    end
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

