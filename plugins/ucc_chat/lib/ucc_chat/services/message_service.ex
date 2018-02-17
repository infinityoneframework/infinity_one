defmodule UccChat.MessageService do
  use UccChat.Shared, :service

  import Ecto.Query

  alias Ecto.Multi
  alias UccChat.{
    Message, Mention, Subscription, ChatDat, Channel,
    MessageAgent, AttachmentService
  }
  alias UccChatWeb.{MessageView}
  alias UccChat.ServiceHelpers, as: Helpers
  alias UcxUcc.Accounts
  # alias UccChat.Schema.Message, as: MessageSchema

  require UccChat.ChatConstants, as: CC
  require Logger

  @preloads [:user, :edited_by, :attachments, :reactions]

  def preloads, do: @preloads

  def delete_message(%{attachments: attachments} = message)
    when is_list(attachments) do

    Logger.warn "deprecated"

    Multi.new
    |> Multi.delete(:message, message)
    |> Multi.run(:attachments, &delete_attachments(&1, message.attachments))
    |> Repo.transaction
    |> case do
      {:ok, _} -> {:ok, message}
      error -> error
    end
  end

  def delete_message(message) do
    Logger.warn "deprecated"
    message
    |> Repo.preload([:attachments])
    |> delete_message
  end

  defp delete_attachments(_, attachments) do
    Logger.warn "deprecated"
    attachments
    |> Enum.map(fn attachment ->
      AttachmentService.delete_attachment attachment
    end)
    |> Enum.any?(&(elem(&1, 0) == :error))
    |> case do
      true -> {:error, :attachment}
      _    -> {:ok, :attachment}
    end
  end

  def get_messages_info(%{} = page, channel_id, user) do
    Logger.warn "deprecated"
    subscription = Subscription.get(channel_id, user.id)
    last_read = Map.get(subscription || %{}, :last_read, "")

    %{}
    |> Map.put(:page, %{
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages
    })
    |> Map.put(:can_preview, true)
    |> Map.put(:last_read, last_read)
  end

  def get_messages_info(messages, channel_id, user) do
    Logger.warn "deprecated"
    subscription = Subscription.get(channel_id, user.id)
    has_more =
      with [first|_] <- messages,
           _ <- Logger.debug("get_messages_info 2"),
           first_msg when not is_nil(first_msg) <-
            Message.first_message(channel_id) do
        first.id != first_msg.id
      else
        _res -> false
      end
    has_more_next =
      with last when not is_nil(last) <- List.last(messages),
           last_msg when not is_nil(last_msg) <-
              Message.last_message(channel_id) do
        last.id != last_msg.id
      else
        _res -> false
      end

   %{
      has_more: has_more,
      has_more_next: has_more_next,
      can_preview: true,
      last_read: Map.get(subscription || %{}, :last_read, ""),
    }
  end

  # TODO: This should be called merge, not into
  def messages_info_into(messages, channel_id, user, params) do
    Logger.warn "deprecated"
    messages |> get_messages_info(channel_id, user) |> Map.merge(params)
  end

  def last_user_id(channel_id) do
    Logger.warn "deprecated"
    case Message.last_message channel_id do
      nil     -> nil
      message -> Map.get(message, :user_id)
    end
  end

  def embed_link_previews(body, channel_id, message_id) do
    Logger.warn "deprecated"
    if UccSettings.embed_link_previews() do
      case get_preview_links body do
        [] ->
          :ok
        list ->
          do_embed_link_previews(list, channel_id, message_id)
      end
    end
  end

  def get_preview_links(nil), do: []
  def get_preview_links(body) do
    Logger.warn "deprecated"
    ~r/https?:\/\/[^\s]+/
    |> Regex.scan(body)
    |> List.flatten
  end

  def do_embed_link_previews(list, channel_id, message_id) do
    Logger.warn "deprecated"
    room = (Channel.get(channel_id) || %{}) |> Map.get(:name)

    Enum.each(list, fn url ->
      spawn fn ->
        case MessageAgent.get_preview url do
          nil ->

            html =
              MessageAgent.put_preview url, create_link_preview(url, message_id)

            broadcast_link_preview(html, room, message_id)
          html ->
            spawn fn ->
              :timer.sleep(100)
              broadcast_link_preview(html, room, message_id)
            end
        end
      end
    end)
  end

  defp create_link_preview(url, _message_id) do
    Logger.warn "deprecated"
    case LinkPreview.create url do
      {:ok, page} ->
        img =
          case Enum.find(page.images, &String.match?(&1[:url], ~r/https?:\/\//)) do
            %{url: url} -> url
            _ -> nil
          end

        "link_preview.html"
        |> MessageView.render(page: struct(page, images: img))
        |> Helpers.safe_to_string

      _ -> ""
    end
  end

  defp broadcast_link_preview(nil, _room, _message_id) do
    Logger.warn "deprecated"
    nil
  end
  defp broadcast_link_preview(html, room, message_id) do
    Logger.warn "deprecated"
    # Logger.warn "broadcasting a preview: room: #{inspect room}, message_id: #{inspect message_id}, html: #{inspect html}"
    UcxUccWeb.Endpoint.broadcast! CC.chan_room <> room, "message:preview",
      %{html: html, message_id: message_id}
  end

  def message_previews(user_id, %{entries: entries}) do
    Logger.warn "deprecated"
    message_previews(user_id, entries)
  end
  def message_previews(user_id, messages) when is_list(messages) do
    Logger.warn "deprecated"
    Enum.reduce messages, [], fn message, acc ->
      case get_preview_links(message.body) do
        [] -> acc
        list ->
          html_list = get_preview_html(list)
          for {url, html} <- html_list, is_nil(html) do
            spawn fn ->
              html = MessageAgent.put_preview url, create_link_preview(url, message.id)
              UcxUccWeb.Endpoint.broadcast!(CC.chan_user <> user_id, "message:preview",
                %{html: html, message_id: message.id})
            end
          end
          [{message.id, html_list} | acc]
      end
    end
  end

  defp get_preview_html(list) do
    Logger.warn "deprecated"
    Enum.map list, &({&1, MessageAgent.get_preview(&1)})
  end

  def encode_mentions(body, channel_id) do
    Logger.warn "deprecated"
    body
    |> encode_user_mentions(channel_id)
    |> encode_channel_mentions
  end

  def encode_channel_mentions({body, acc}) do
    Logger.warn "deprecated"
    re = ~r/(^|\s|\!|:|,|\?)#([\.a-zA-Z0-9_-]*)/
    body =
      if (list = Regex.scan(re, body)) != [] do
        Enum.reduce(list, body, fn [_, _, name], body ->
          encode_channel_mention(name, body)
        end)
      else
        body
      end
    {body, acc}
  end

  def encode_channel_mention(name, body) do
    Logger.warn "deprecated"
    Channel.get_by(name: name)
    |> do_encode_channel_mention(name, body)
  end

  def do_encode_channel_mention(nil, _, body) do
    Logger.warn "deprecated"
    body
  end
  def do_encode_channel_mention(_channel, name, body) do
    Logger.warn "deprecated"
    name_link = " <a class='mention-link' data-channel='#{name}'>##{name}</a> "
    String.replace body, ~r/(^|\s|\.|\!|:|,|\?)##{name}[\.\!\?\,\:\s]*/, name_link
  end

  def encode_user_mentions(body, channel_id) do
    Logger.warn "deprecated"
    re = ~r/(^|\s|\!|:|,|\?)@([\.a-zA-Z0-9_-]*)/
    if (list = Regex.scan(re, body)) != [] do
      Enum.reduce(list, {body, []}, fn [_, _, name], {body, acc} ->
        encode_user_mention(name, body, channel_id, acc)
      end)
    else
      {body, []}
    end
  end

  def encode_user_mention(name, body, channel_id, acc) do
    Logger.warn "deprecated"
    User
    |> where([c], c.username == ^name)
    |> Repo.one
    |> do_encode_user_mention(name, body, channel_id, acc)
  end

  def do_encode_user_mention(nil, name, body, _, acc)
    when name in ~w(all here) do
    Logger.warn "deprecated"
    name_link = " <a class='mention-link mention-link-me mention-link-" <>
      "#{name} background-attention-color' >@#{name}</a> "
    body = String.replace body,
      ~r/(^|\s|\.|\!|:|,|\?)@#{name}[\.\!\?\,\:\s]*/, name_link
    {body, [{nil, name}|acc]}
  end
  def do_encode_user_mention(nil, _, body, _, acc) do
    Logger.warn "deprecated"
    {body, acc}
  end
  def do_encode_user_mention(user, name, body, _channel_id, acc) do
    Logger.warn "deprecated"
    name_link =
      " <a class='mention-link' data-username='#{user.username}'>@#{name}</a> "
    body =
      String.replace body, ~r/(^|\s|\.|\!|:|,|\?)@#{name}[\.\!\?\,\:\s]*/,
        name_link
    {body, [{user.id, name}|acc]}
  end

  def update_mentions([], _, _, _) do
    Logger.warn "deprecated"
    :ok
  end
  def update_mentions([mention|mentions], message_id, channel_id, body) do
    Logger.warn "deprecated"
    update_mention(mention, message_id, channel_id, body)
    update_mentions(mentions, message_id, channel_id, body)
  end

  def update_mention({nil, _}, _, _, _) do
    Logger.warn "deprecated"
    nil
  end
  def update_mention({mention, name}, message_id, channel_id, body) do
    Logger.warn "deprecated"
    case Accounts.get_by_user(username: name)  do
      nil -> :error
      user ->
        case Mention.list_by(message_id: message_id, user_id: user.id) do
          [] -> create_mention({mention, name}, message_id, channel_id, body)
          _list -> :ok
        end
    end
  end

  def create_mentions([], _, _, _) do
    Logger.warn "deprecated"
    :ok
  end
  def create_mentions([mention|mentions], message_id, channel_id, body) do
    Logger.warn "deprecated"
    create_mention(mention, message_id, channel_id, body)
    create_mentions(mentions, message_id, channel_id, body)
  end

  def create_mention({_, _}, _, _, _) do
    Logger.warn "deprecated"
    nil
  end

  def update_direct_notices(%{type: 2, id: id}, %{user_id: user_id}) do
    Logger.warn "deprecated"
    id
    |> Subscription.get_by_channel_id_and_not_user_id(user_id)
    |> Enum.each(fn %{unread: unread} = sub ->
      Subscription.update(sub, %{unread: unread + 1})
    end)
  end
  def update_direct_notices(_channel, _message) do
    Logger.warn "deprecated"
    nil
  end

  def render_message_box(channel_id, user_id) do
    Logger.warn "deprecated"
    user = Helpers.get_user! user_id
    channel =
      case Channel.get(channel_id) do
        nil ->
          Channel.first
        channel ->
          channel
      end
    chatd = ChatDat.new(user, channel)

    "message_box.html"
    |> MessageView.render(chatd: chatd, mb: MessageView.get_mb(chatd))
    |> Helpers.safe_to_string
  end
end
