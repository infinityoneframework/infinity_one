defmodule OneChatWeb.FlexBar.Tab.Mention do
  use OneChatWeb.FlexBar.Helpers
  alias OneChat.Mention
  alias InfinityOne.TabBar.Tab

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel direct im],
      "mentions",
      ~g"Mentions",
      "icon-at",
      View,
      "mentions.html",
      70)
  end

  def args(socket, {user_id, channel_id, _, _}, _) do
    mentions =
      user_id
      |> Mention.get_by_user_id_and_channel_id(channel_id)
      |> do_messages_args(user_id, channel_id)

    {[mentions: mentions], socket}
  end
end

