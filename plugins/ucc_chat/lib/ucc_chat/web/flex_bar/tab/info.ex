defmodule UccChat.Web.FlexBar.Tab.Info do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.Channel

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel direct],
      id: "info",
      title: ~g"Info",
      icon: "icon-info-circled",
      view: View,
      template: "channel_settings.html",
      order: 10
    }
  end

  def args(user_id, channel_id, _, _) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id)
    [channel: settings_form_fields(channel, user_id),
     current_user: current_user, channel_type: channel.type]
  end
end

