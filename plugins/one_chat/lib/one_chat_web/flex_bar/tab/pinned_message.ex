defmodule OneChatWeb.FlexBar.Tab.PinnedMessage do
  use OneChatWeb.FlexBar.Helpers

  alias OneChat.PinnedMessage
  alias InfinityOne.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel],
      "pinned-messages",
      ~g"Pinned Messages",
      "icon-pin",
      View,
      "pinned_messages.html",
      90)
  end

  def args(socket, {user_id, channel_id, _, _}, _) do
    pinned =
      channel_id
      |> PinnedMessage.get_by_channel_id()
      |> do_pinned_messages_args(user_id, channel_id)

    {[pinned: pinned], socket}
  end
end

