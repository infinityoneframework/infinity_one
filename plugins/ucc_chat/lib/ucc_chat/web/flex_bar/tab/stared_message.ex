defmodule UccChat.Web.FlexBar.Tab.StaredMessage do
  alias UccChat.StaredMessage
  use UccChat.Web.FlexBar.Helpers

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel direct im],
      id: "stared-messages",
      title: ~g"Stared Messages",
      icon: "icon-star",
      view: View,
      template: "stared_messages.html",
      order: 80
    }
  end

  def args(user_id, channel_id, _, _) do
    stars =
      channel_id
      |> StaredMessage.get_by_channel_id()
      |> do_messages_args(user_id, channel_id)
    [stars: stars]
  end
end

