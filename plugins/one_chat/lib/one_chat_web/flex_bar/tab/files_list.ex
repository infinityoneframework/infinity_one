defmodule OneChatWeb.FlexBar.Tab.FilesList do
  use OneChatWeb.FlexBar.Helpers

  alias OneChat.Attachment
  alias InfinityOne.TabBar.Tab

  @spec add_buttons() :: any
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group direct im],
      "uploaded-files-list",
      ~g"Room uploaded file list",
      "icon-attach",
      View,
      "files_list.html",
      60)
  end

  @spec args(socket, {id, id, any, map}, args) :: {List.t, socket}
  def args(socket, {user_id, channel_id, _, _}, _) do
    {[
      current_user: Helpers.get_user!(user_id),
      attachments: Attachment.get_attachments_by_channel_id(channel_id)
    ], socket}
  end
end

