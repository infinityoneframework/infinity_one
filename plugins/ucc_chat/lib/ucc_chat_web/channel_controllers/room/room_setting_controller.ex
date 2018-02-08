defmodule UccChatWeb.RoomSettingChannelController do
  use UccChatWeb, :channel_controller

  alias UccChat.{Subscription, Web.FlexBarView, Channel, ChannelService}
  alias UccChatWeb.FlexBarView
  alias UccChat.ServiceHelpers, as: Helpers

  require Logger

  def edit(%{assigns: assigns} = socket, params) do
    channel = Channel.get(assigns[:channel_id])
    field_name = String.to_atom(params["field_name"])
    value = Map.get channel, field_name

    html =
      "channel_form_text_input.html"
      |> FlexBarView.render(field: %{name: field_name, value: value})
      |> Helpers.safe_to_string

    {:reply, {:ok, %{html: html}}, socket}
  end

  def update_field(%{assigns: assigns} = socket, channel, _user,
    %{"field_name" => "archived", "value" => true}) do
    ChannelService.channel_command(socket, :archive, channel,
      assigns.user_id, channel.id)
  end

  def update_field(%{assigns: assigns} = socket, channel, _user,
    %{"field_name" => "archived"}) do
    ChannelService.channel_command(socket, :unarchive, channel,
      assigns.user_id, channel.id)
  end

  def update_field(%{assigns: _assigns} = _socket, channel, user,
    %{"field_name" => field_name, "value" => value}) do
    channel
    |> Channel.changeset_settings(user, [{field_name, value}])
    |> Repo.update
  end

  def update_archive_hidden(%{id: id} = channel, "archived", value) do
    value = if value == true, do: true, else: false

    Subscription.get_by(channel_id: id)
    |> Repo.update_all(set: [hidden: value])

    channel
  end

  def update_archive_hidden(channel, _type, _value), do: channel
end
