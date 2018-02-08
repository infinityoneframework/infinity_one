defmodule UccChat.Mention do
  use UccModel, schema: UccChat.Schema.Mention

  alias UccChat.{Subscription, Channel}
  alias UccChatWeb.UserChannel
  alias UcxUcc.Accounts

  require Logger

  def count(channel_id, user_id) do
    from m in @schema,
      where: m.user_id == ^user_id and m.channel_id == ^channel_id,
      select: count(m.id)
  end

  def get_by_user_id_and_channel_id(user_id, channel_id) do
    @schema
    |> where([m], m.user_id == ^user_id and m.channel_id == ^channel_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user, message: :user])
    |> @repo.all
  end

  def parse(nil), do: []
  def parse(body) do
    ~r/(?:^|[\s\!:,\?])(?:@)([\.a-zA-Z0-9_-]+)/
    |> Regex.scan(body)
    |> Enum.map(&Enum.at(&1, 1))
  end

  @all_names ~w(all all! here)

  def create_from_message(%{body: body} = message) do
    body
    |> parse()
    |> create_many(message)
  end

  def create_many(mentions, %{id: message_id, channel_id: channel_id, body: body}) do
    Enum.reduce(mentions, [], fn username, acc ->
      user = Accounts.get_by_username(username)
      if username in ~w(all all! here) or user do
        # don't allow the creation of mentions in direct channels right not
        # TODO: This is where we want to add a feature to create a new public
        #       channel if someone at mentions another parity in a direct channel.
        if Channel.get(channel_id) |> Map.get(:type) == 2 do
          acc
        else
          do_create(username, user, message_id, channel_id, body)
        end
      else
        acc
      end
    end)
  end

  def do_create(name, user, message_id, channel_id, body) do
    {all, nm} = if name in @all_names, do: {true, name}, else: {false, nil}
    user_id = Map.get(user, :id)
    %{
      user_id: user_id,
      all: all,
      name: nm,
      message_id: message_id,
      channel_id: channel_id
    }
    |> create
    |> case do
      {:ok, mention} ->
        UserChannel.notify_mention(mention, body)
        if user_id do
          Subscription.join_new(user_id, channel_id, unread: true)
        end
        mention
      error -> error
    end
  end

  def update_from_message(%{body: body} = message) do
    body
    |> parse()
    |> update_many(message)
  end

  def update_many(mentions, %{id: message_id, channel_id: channel_id, body: body}) do
    existing = list_by(message_id: message_id, preload: [:user])
    existing_names =
      Enum.map(existing, fn mention ->
        if mention.user_id, do: mention.user.username, else: mention.name
      end)

    adds = mentions -- existing_names
    subs = existing_names -- mentions

    Enum.each adds, fn name ->
      user = Accounts.get_by_username(name)
      do_create(name, user, message_id, channel_id, body)
    end

    Enum.each subs, fn name ->
      existing
      |> Enum.find(& &1.user_id == name or &1.name == name)
      |> delete
    end
  end
end
