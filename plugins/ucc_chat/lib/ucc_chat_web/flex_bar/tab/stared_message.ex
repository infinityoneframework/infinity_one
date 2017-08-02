defmodule UccChatWeb.FlexBar.Tab.StaredMessage do
  use UccChatWeb.FlexBar.Helpers

  alias UccChat.StaredMessage
  alias UcxUcc.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel direct im],
      "stared-messages",
      ~g"Stared Messages",
      "icon-star",
      View,
      "stared_messages.html",
      80)
  end

  def args(socket, user_id, channel_id, _, _) do
    stars =
      channel_id
      |> StaredMessage.get_by_channel_id()
      |> do_messages_args(user_id, channel_id)
    {[stars: stars], socket}
  end
end

