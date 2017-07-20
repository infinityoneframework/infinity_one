defmodule UccChat.Web.FlexBar.Tab.PinnedMessage do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.PinnedMessage

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel],
      id: "pinned-messages",
      title: ~g"Pinned Messages",
      icon: "icon-pin",
      view: View,
      template: "pinned_messages.html",
      order: 90
    }
  end

  def args(user_id, channel_id, _, _) do
    pinned =
      channel_id
      |> PinnedMessage.get_by_channel_id()
      |> do_messages_args(user_id, channel_id)

    [pinned: pinned]
  end
end

