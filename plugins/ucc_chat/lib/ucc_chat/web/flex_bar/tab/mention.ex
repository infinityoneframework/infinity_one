defmodule UccChat.Web.FlexBar.Tab.Mention do
  use UccChat.Web.FlexBar.Helpers
  alias UccChat.Mention

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel direct im],
      id: "mentions",
      title: ~g"Mentions",
      icon: "icon-at",
      view: View,
      template: "mentions.html",
      order: 70
    }
  end

  def args(user_id, channel_id, _, _) do
    mentions =
      user_id
      |> Mention.get_by_user_id_and_channel_id(channel_id)
      |> do_messages_args(user_id, channel_id)

    [mentions: mentions]
  end
end

