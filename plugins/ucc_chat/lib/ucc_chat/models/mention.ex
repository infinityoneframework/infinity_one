defmodule UccChat.Mention do
  use UccModel, schema: UccChat.Schema.Mention

  # TODO: I don't think we would be using gettext here, but not sure
  #       how else to do it right now.
  import UcxUccWeb.Gettext

  import UcxUcc.Permissions, only: [has_permission?: 3]

  alias UccChat.{Subscription, Channel, Direct, Message}
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
    ~r/(?:^|[\s\!:,\?])(?:@)([\.a-zA-Z0-9_-]+\!?)/
    |> Regex.scan(body)
    |> Enum.map(&Enum.at(&1, 1))
  end

  @all_names ~w(all all! here)

  def create_from_message(%{system: true}) do
    nil
  end

  def create_from_message(%{body: body} = message) do
    body
    |> parse()
    |> create_many(message)
    |> check_and_create_nway(message)
  end

  def create_many(mentions, %{id: message_id, user_id: owner_id, channel_id: channel_id, body: body}) do
    Enum.reduce(mentions, [], fn username, acc ->
      user = Accounts.get_by_username(username)
      if username in @all_names or user do
        channel = Channel.get(channel_id)

        channel_type =
          cond do
            channel.type == 2 -> :direct
            channel.nway -> :nway
            true -> false
          end

        case {channel_type, user} do
          {:direct, nil} ->
            # must be one of all, all!, or here
            acc
          {:direct, %{id: ^owner_id}} ->
            # mentioned themself.
            [do_create(username, user, message_id, channel_id, body) | acc]
          {:direct, user} ->
            # either the friend of another user
            user_id = Map.get(user, :id)
            mention =
              case Direct.get owner_id, user_id, channel_id do
                # different user, lets create a new private channel
                nil ->
                  # highlight for later processing
                  {:nway, user}
                _ ->
                  # mentioned the friend. We can create the mention
                  do_create(username, user, message_id, channel_id, body)
              end
            [mention | acc]

          {:nway, user} ->
            name = channel.name <> nway_name_segment(user)
            unless Subscription.get(channel_id, user.id) || nway_renamed?(channel) || String.length(name) > 40 do
              Channel.update(channel, %{name: name})
            end

            [do_create(username, user, message_id, channel_id, body) | acc]

          {_, user} ->
            # public or private channel
            [do_create(username, user, message_id, channel_id, body) | acc]
        end
      else
        acc
      end
    end)
  end

  def nway_renamed?(channel) do
    names =
      channel.name
      |> String.replace(~r/([A-Z])/, "_\\1")
      |> String.split("_", trim: true)
      |> Enum.map(&String.downcase/1)

    subscribed_names =
      channel.id
      |> Subscription.usernames_by_channel_id()
      |> Enum.map(&String.downcase/1)

    names -- subscribed_names != []
  end

  defp get_nways(mentions) do
    Enum.reduce mentions, [], fn
      {:nway, user}, acc -> [user | acc]
      _, acc -> acc
    end
  end

  defp nway_name_segment(%{username: username}) do
    nway_name_segment username
  end

  defp nway_name_segment(username) do
    username |> String.downcase |> String.capitalize
  end

  def check_and_create_nway(mentions, message) do
    owner_id = message.user_id
    case get_nways mentions do
      [] -> mentions
      others ->
        owner = Accounts.get_user owner_id
        friend =
          owner_id
          |> Direct.get_friend(message.channel_id, preload: [:friend])
          |> Map.get(:friend)

        user_list = [owner, friend | others]
        names = Enum.map user_list, & &1.username
        user_id_list = Enum.map user_list, & &1.id
        case Channel.get_nway(user_id_list) do
          nil ->
            user_list
            |> Enum.map(&nway_name_segment/1)
            |> Enum.join("")
            |> Channel.create_channel(owner.id, %{type: 1, nway: true})
            |> case do
              {:ok, channel} ->
                # need to subscribe the owner and friend now
                Subscription.join_new(owner_id, channel.id, unread: true)
                Subscription.join_new(friend.id, channel.id, unread: true)

                # create mention and subscribe the 3rd party(ies)
                Enum.map(others, fn other ->
                  do_create(other.username, other, message.id, channel.id, message.body)
                end)

                # create a system message indicating that a new channel
                # has been created with the users
                create_nway_system_message(message, channel.name, names)
                {:ok, channel}
              error ->
                error
            end
          channel ->
            {:ok, channel}
        end
        |> case do
          {:ok, channel} ->
            # post the message to the channel, which may be a now one, or
            # an exiting channel
            Message.create(%{
              channel_id: channel.id,
              user_id: owner_id,
              body: message.body
            })
            channel
          error ->
            error
        end
    end
  end

  def do_create(name, _user, message_id, channel_id, _body) when name in @all_names do
    poster =
      message_id
      |> Message.get_user_id()
      |> Accounts.get_user(default_preload: true)

    attrs = %{all: true, name: name, message_id: message_id, channel_id: channel_id}

    poster
    |> mention_all_users(name, channel_id)
    |> Enum.map(fn user ->
      attrs
      |> Map.put(:user_id, user.id)
      |> create
      |> case do
        {:ok, mention} -> mention
        error          -> error
      end
    end)
  end

  def do_create(_name, user, message_id, channel_id, _body) do
    {all, nm, user} = {false, nil, user}
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

  defp create_nway_system_message(message, room, names) do
    # we want this message to be posted after the message that creates
    # the new n-way channel. So, we'll spawn and sleep for a bit.
    spawn fn ->
      # the order of the messages seem to only be at 1 sec resolution.
      # until I can fix this, we'll delay for 1 second to ensure that
      # this message is displayed after the previous message.
      Process.sleep 1000

      first_name = "@" <> hd(names)
      other_names =
        names
        |> tl()
        |> Enum.map(& "@" <> &1)
        |> Enum.join(", ")

      # TODO: Find a better way to handle using web module Gettext
      #       here in this lib.
      body =
        gettext(
          "A new n-way private channel #%{room} has been created" <>
          " for %{names}, and %{name}",
          names: other_names, name: first_name, room: room)


      Message.create(%{
        channel_id: message.channel_id,
        user_id: Accounts.get_bot_id(),
        body: body,
        system: true
      })
    end
  end

  defp mention_all_users(poster, name, channel_id) do
    preload = [:roles, user_roles: :role]
    max = UccSettings.max_members_disable_notifications()

    case name do
      "all" ->
        if has_permission?(poster, "mention-all", channel_id) && Subscription.count(channel_id) <= max do
          Subscription.get_all_users_for_channel(channel_id, preload: preload)
        else
          []
        end
      "here" ->
        if has_permission?(poster, "mention-here", channel_id) && Subscription.open_count(channel_id) <= max do
          Subscription.get_all_users_for_channel(channel_id, open: true, preload: preload)
        else
          []
        end
      "all!" ->
        if has_permission?(poster, "mention-all!", channel_id) && Subscription.open_count(channel_id) <= max do
          UccChat.ChannelMonitor.get_users()
          |> Enum.map(fn user_id ->
            user = Accounts.get_user user_id
            if open_subscription = Subscription.get_by(user_id: user.id, open: true, preload: [:channel]) do
              struct(user, open_id: open_subscription.channel.id)
            else
              user
            end
          end)
        end
      true ->
        []
    end
  end
end
