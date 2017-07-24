defmodule UccChat.Web.FlexBar.Tab.Info do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.Channel
  alias UcxUcc.TabBar.Tab

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

  def args(socket, user_id, channel_id, _, _) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id)
    {[channel: settings_form_fields(channel, user_id),
     current_user: current_user, channel_type: channel.type], socket}
  end
end

