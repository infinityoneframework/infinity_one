defmodule UccChat.Web.FlexBar.Tab.Mention do
  use UccChat.Web.FlexBar.Helpers
  alias UccChat.Schema.Mention, as: MentionSchema

  alias UccChat.Channel

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

  def args(user_id, channel_id, _, opts) do
    mentions =
      MentionSchema
      |> where([m], m.user_id == ^user_id and m.channel_id == ^channel_id)
      |> preload([:user, :message])
      |> Repo.all
      |> do_messages_args(user_id, channel_id)

    [mentions: mentions]
  end
end

