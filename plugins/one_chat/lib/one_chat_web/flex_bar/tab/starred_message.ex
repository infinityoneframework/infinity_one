defmodule OneChatWeb.FlexBar.Tab.StarredMessage do
  use OneChatWeb.FlexBar.Helpers

  alias OneChat.StarredMessage
  alias InfinityOne.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel direct im],
      "starred-messages",
      ~g"Starred Messages",
      "icon-star",
      View,
      "starred_messages.html",
      80)
  end

  def args(socket, {user_id, channel_id, _, _}, _) do
    stars =
      channel_id
      |> StarredMessage.get_by_channel_id_and_user_id(user_id)
      |> do_messages_args(user_id, channel_id)
    {[stars: stars], socket}
  end
end

