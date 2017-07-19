defmodule UccChat.Web.FlexBar.Tab.FilesList do
  use UccChat.Web.FlexBar.Helpers

  alias UccChat.Channel
  alias UccChat.Schema.Message, as: MessageSchema
  alias UccChat.Schema.Attachement, as: AttachmentSchema

  def add_buttons do
    TabBar.add_button %{
      module: __MODULE__,
      groups: ~w[channel group direct im],
      id: "uploaded-files-list",
      title: ~g"Room uploaded file list",
      icon: "icon-attach",
      view: View,
      template: "files_list.html",
      order: 60
    }
  end

  def args(user_id, channel_id, _, _) do
    current_user = Helpers.get_user! user_id
    channel = Channel.get!(channel_id)
    attachments = (from a in AttachmentSchema,
      join: m in MessageSchema, on: a.message_id == m.id,
      order_by: [desc: m.timestamp],
      where: a.channel_id == ^(channel.id))
    |> Repo.all
    [current_user: current_user, attachments: attachments]
  end
end

