defmodule OneChatWeb.MessageChannelController do
  use OneChatWeb, :channel_controller
  use OneLogger

  alias OneChat.{
    Message, Attachment,
    AttachmentService
  }
  alias InfinityOne.Permissions
  alias OneChat.ServiceHelpers, as: Helpers
  alias OneChatWeb.RoomChannel.Message, as: WebMessage

  require Logger

  def index(%{assigns: assigns} = socket, params) do
    Logger.debug fn -> "params: " <> inspect(params) end

    user = Helpers.get_user(assigns[:user_id], preload: [:subscriptions])
    channel_id = assigns[:channel_id]
    preloads = Message.preloads()

    page =
      Message.get_messages(channel_id, user, preload: preloads,
        page: params["page"])

    messages_html = render_messages(page.entries, user)

    {:reply, {:ok, WebMessage.messages_info_into(page, channel_id,
      user, %{html: messages_html})}, socket}
  end

  def previous(%{assigns: assigns} = socket, params) do
    Logger.debug "params: " <> inspect(params)
    user = Helpers.get_user(assigns[:user_id], preload: [])

    channel_id = assigns[:channel_id]
    timestamp = params["timestamp"]

    preloads = Message.preloads()

    page =
      Message.get_messages(channel_id, user, preload: preloads,
        page: params["page"])

    messages_html = render_messages(page.entries, user)

    {:reply, {:ok, WebMessage.messages_info_into(page, channel_id,
      user, %{html: messages_html, last_read: timestamp})}, socket}
  end

  def surrounding(%{assigns: assigns} = socket, params) do

    user = Helpers.get_user(assigns[:user_id], preload: [])
    channel_id = assigns[:channel_id]
    timestamp = params["timestamp"]

    page = Message.get_surrounding_messages(channel_id, timestamp, user, params["page"] || [])

    messages_html = render_messages(page.entries, user)

    {:reply, {:ok, WebMessage.messages_info_into(page, channel_id,
      user, %{html: messages_html})}, socket}
  end

  defp render_messages(entries, user) do
    previews = WebMessage.message_previews(user.id, entries)

    entries
    |> Enum.map(fn message ->
      previews = List.keyfind(previews, message.id, 0, {nil, []}) |> elem(1)
      "message.html"
      |> OneChatWeb.MessageView.render(user: user, message: message,
        previews: previews, message_opts: OneChatWeb.MessageView.message_opts())
      |> Helpers.safe_to_string
    end)
    |> to_string
    |> String.replace("\n", "")
  end

  # new version of this in room_channel/message.ex
  def delete(%{assigns: assigns} = socket, params) do
    Logger.warn "deprecated"
    user = Helpers.get_user assigns.user_id
    if user.id == params["message_id"] ||
      Permissions.has_permission?(user, "delete-message", assigns.channel_id) do
      message = Message.get params["message_id"], preload: [:attachments]
      case Message.delete message do
        {:ok, _} ->
          Phoenix.Channel.broadcast! socket, "code:update",
            %{selector: "li.message#" <> params["message_id"], action: "remove"}
        _ ->
          Phoenix.Channel.push socket, "toastr:error",
            %{error: ~g(There was an error deleting that message)}
      end
    else
      push_error socket, ~g(You are not authorized to delete that message)
    end
    {nil, %{}}
  end

  defp push_error(socket, error) do
    Phoenix.Channel.push socket, "toastr:error", %{error: error}
  end

  def delete_attachment(%{assigns: assigns} = socket, params) do
    user = Helpers.get_user assigns[:user_id], preload: []
    attachment = Attachment.get params["id"], preload: [:message]
    message = attachment.message
    if user.id == message.user_id ||
      Permissions.has_permission?(user, "delete-message", assigns.channel_id) do

      case AttachmentService.delete_attachment(attachment) do
        {:error, _} ->
          push_error socket, ~g(There was a problem deleting that file)
        _ -> nil
      end
      message = Repo.preload(message, [:attachments])

      if length(message.attachments) == 0 do
        Repo.delete message
        Phoenix.Channel.broadcast! socket, "code:update",
          %{selector: "li.message#" <> attachment.message.id, action: "remove"}
      else
        # broadcast edited message update
      end
      Phoenix.Channel.broadcast! socket, "code:update",
        %{selector: "li[data-id='" <> attachment.id <> "']", action: "remove"}
    else
      push_error socket, ~g(You are not authorized to delete that attachment)
    end
    {:reply, {:ok, %{}}, socket}
  end
end
