defmodule UccChatWeb.MessageChannelController do
  use UccChatWeb, :channel_controller
  use UccLogger

  import UccChat.MessageService

  alias UccChat.{
    Message, MessageService, Attachment,
    AttachmentService
  }
  alias UcxUcc.Permissions
  # alias UcxUcc.Accounts.User
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.Schema.Message, as: MessageSchema
  # alias UccChatWeb.RebelChannel.Client

  require Logger

  # def create(%{assigns: assigns} = socket, params) do
  #   # Logger.warn "++++ socket: #{inspect socket}"
  #   message = params["message"]
  #   user_id = assigns[:user_id]
  #   channel_id = assigns[:channel_id]

  #   create message, channel_id, user_id, socket

  #   {:noreply, socket}
  # end

  # def create(message, channel_id, user_id, socket) do
  #   Logger.error "create ..."
  #   user = Helpers.get_user user_id
  #   channel = Channel.get!(channel_id)
  #   msg_params = if Channel.direct?(channel), do: %{type: "d"}, else: %{}

  #   cond do
  #     ChannelService.user_muted? user_id, channel_id ->
  #       # sys_msg = create_private_message(channel_id,
  #       #   ~g"You have been muted and cannot speak in this room")
  #       # html = render_message(sys_msg)
  #       # push_message(socket, sys_msg.id, user_id, html)
  #       MessageService.broadcast_private_message(channel_id, user_id,
  #         ~g"You have been muted and cannot speak in this room")

  #       # msg = create_message(message, user_id, channel_id, %{ type: "p", })
  #       # html = render_message(msg)
  #       # push_message(socket, msg.id, user_id, html)

  #     channel.read_only and
  #       not Permissions.has_permission?(user, "post-readonly", channel_id) ->

  #       Client.toastr socket, :error,
  #         ~g(You are not authorized to create a message)
  #     channel.archived ->
  #       Client.toastr socket, :error,
  #         ~g(You are not authorized to create a message)
  #     true ->
  #       {body, mentions} = encode_mentions(message, channel_id)
  #       UccChat.RobotService.new_message body, channel, user

  #       message = create_message(body, user_id, channel_id, msg_params)
  #       create_mentions(mentions, message.id, message.channel_id, body)
  #       update_direct_notices(channel, message)
  #       message_html = render_message(message)
  #       broadcast_message(socket, message.id, message.user.id,
  #         message_html, body: body)
  #   end
  #   stop_typing(socket, user_id, channel_id)
  #   socket
  # end

  def index(%{assigns: assigns} = socket, params) do
    user = Helpers.get_user(assigns[:user_id], preload: [])

    channel_id = assigns[:channel_id]
    timestamp = params["timestamp"]

    page_size = Application.get_env :ucx_chat, :page_size, 30
    preloads = MessageService.preloads()

    list =
      MessageSchema
      |> where([m], m.timestamp < ^timestamp and m.channel_id == ^channel_id)
      |> Helpers.last_page(page_size)
      |> preload(^preloads)
      |> Repo.all

    previews = MessageService.message_previews(user.id, list)

    messages_html =
      list
      |> Enum.map(fn message ->
        previews = List.keyfind(previews, message.id, 0, {nil, []}) |> elem(1)
        "message.html"
        |> UccChatWeb.MessageView.render(user: user, message: message,
          previews: previews)
        |> Helpers.safe_to_string
      end)
      |> to_string

    messages_html = String.replace(messages_html, "\n", "")

    {:reply, {:ok, MessageService.messages_info_into(list, channel_id,
      user, %{html: messages_html})}, socket}
  end

  def previous(%{assigns: assigns} = socket, params) do
    user = Helpers.get_user(assigns[:user_id], preload: [])

    channel_id = assigns[:channel_id]
    timestamp = params["timestamp"]

    page_size = Application.get_env :ucx_chat, :page_size, 75
    preloads = MessageService.preloads()
    list =
      MessageSchema
      |> where([m], m.timestamp > ^timestamp and m.channel_id == ^channel_id)
      |> limit(^page_size)
      |> preload(^preloads)
      |> Repo.all

    previews = MessageService.message_previews(user.id, list)

    messages_html =
      list
      |> Enum.map(fn message ->
        previews = List.keyfind(previews, message.id, 0, {nil, []}) |> elem(1)

        "message.html"
        |> UccChatWeb.MessageView.render(user: user, message: message,
          previews: previews)
        |> Helpers.safe_to_string
      end)
      |> to_string

    messages_html = String.replace(messages_html, "\n", "")

    {:reply, {:ok, MessageService.messages_info_into(list, channel_id,
      user, %{html: messages_html})}, socket}
  end

  def surrounding(%{assigns: assigns} = socket, params) do
    user = Helpers.get_user(assigns[:user_id], preload: [])
    channel_id = assigns[:channel_id]
    timestamp = params["timestamp"]


    list = Message.get_surrounding_messages(channel_id, timestamp, user)

    previews = MessageService.message_previews(user.id, list)

    messages_html =
      list
      |> Enum.map(fn message ->
        previews = List.keyfind(previews, message.id, 0, {nil, []}) |> elem(1)

        "message.html"
        |> UccChatWeb.MessageView.render(user: user, message: message,
          previews: previews)
        |> Helpers.safe_to_string
      end)
      |> to_string

    messages_html = String.replace(messages_html, "\n", "")

    {:reply, {:ok, MessageService.messages_info_into(list, channel_id,
      user, %{html: messages_html})}, socket}
  end

  def last(%{assigns: assigns} = socket, _params) do
    user = Helpers.get_user assigns[:user_id], preload: []
    channel_id = assigns[:channel_id]

    list = Message.get_messages(channel_id, user)

    previews = MessageService.message_previews(user.id, list)

    messages_html =
      list
      |> Enum.map(fn message ->
        "message.html"
        |> UccChatWeb.MessageView.render(user: user, message: message,
          previews: previews)
        |> Helpers.safe_to_string
      end)
      |> to_string

    messages_html = String.replace(messages_html, "\n", "")

    {:reply, {:ok, MessageService.messages_info_into(list, channel_id,
      user, %{html: messages_html})}, socket}
  end

  def update(%{assigns: assigns} = socket, params) do
    raise "update not supported"
    user = Helpers.get_user assigns[:user_id], preload: []
    channel_id = assigns[:channel_id]
    id = params["id"]

    value = params["message"]
    message = Message.get(id, preload: [:attachments])
    resp =
      case message.attachments do
        [] ->
          update_message_body(message, value, user)
        [att|_] ->
          update_attachment_description(att, message, value, user)
      end
      |> case do
        {:ok, message} ->
          _message = Repo.preload(message, MessageService.preloads())
          # MessageService.broadcast_updated_message message
          {:ok, %{}}
        _error ->
          {:error, %{error: ~g(Problem updating your message)}}
      end

    stop_typing(socket, user.id, channel_id)
    {:reply, resp, socket}
  end

  # new version of this in room_channel/message.ex
  def delete(%{assigns: assigns} = socket, params) do
    user = Helpers.get_user assigns.user_id
    if user.id == params["message_id"] ||
      Permissions.has_permission?(user, "delete-message", assigns.channel_id) do
      message = Message.get params["message_id"], preload: [:attachments]
      case MessageService.delete_message message do
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

  defp update_attachment_description(attachment, message, value, user) do
    Repo.transaction(fn ->
      message
      |> Message.update(%{edited_id: user.id})
      |> case do
        {:ok, message} ->
          attachment
          |> Attachment.update(%{description: value})
          |> case do
            {:ok, _attachment} ->
              {:ok, message}
            error ->
              Repo.rollback(:attachment_error)
              error
          end
        error -> error
      end
    end)
    |> case do
      {:ok, res} -> res
      {:error, _} -> {:error, nil}
    end
  end

  defp update_message_body(message, value, user) do
    Message.update(message, %{body: value, edited_id: user.id})
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
