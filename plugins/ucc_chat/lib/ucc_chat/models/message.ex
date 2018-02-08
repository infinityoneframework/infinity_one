defmodule UccChat.Message do
  @moduledoc """
  Context for application level message handling.

  Uses the UccModel module to add the standard database functions like:

  * create/1 - runs schema.changeset/2 and then Repo.insert/1
  * update/2
  * delete/1
  * change/1 & change/2
  * get/1, get_by/2
  * list/0 and list/1
  * list_by/1
  * new/0
  * and many more

  Unlike some of the very simple models, there are some highly specialized
  functions in this module. Checkout the `UccChat.Messages.create/`
  function for example.
  """
  use UccModel, schema: UccChat.Schema.Message
  use Timex

  alias UcxUcc.{Repo, Accounts, Permissions}
  alias UccChat.Schema.Channel, as: ChannelSchema
  alias UccChat.{Attachment, Channel, AppConfig, Mention, Subscription}
  alias UccChat.ServiceHelpers, as: Helpers
  alias Ecto.Multi
  alias UcxUcc.{UccPubSub}

  require Logger

  @preloads [:user, :edited_by, :attachments, :reactions, :channel, :mentions]

  def preloads, do: @preloads

  defp get_param(params, key) when is_atom(key) do
    params[key] || params[to_string(key)]
  end

  def create_system_message(channel_id, user_id, body) do
    create(%{
      user_id: user_id,
      channel_id: channel_id,
      body: body,
      system: true,
      sequential: false
    })
  end

  def create_private_message(channel_id, user_id, body, opts \\ []) do
    system = Keyword.get(opts, :system, true)
    create(%{
      type: "p",
      user_id: user_id,
      channel_id: channel_id,
      body: body,
      system: system,
      sequential: false
    })
  end

  @doc """
  Create a new message.

  Before creating a new message, we need to check a number to things
  like permissions, mute status, channel read-only and archived status.

  Messages posted with attachments are also handled here with the help
  of `Ecto.Multi`. So, message params containing the `:attachments` field
  with a list of attachment params will have the attachments rows created
  as will as their associated upload files generated, including any
  applicable poster images.

  See `UccChat.Attachment` and `UccChat.File` for more details.

  Upon successful database insertion, the `UcxUcc.UccPubSub` module is
  used to inform other areas of the application that a new message as
  been posted. Some of the subscribers to the broadcast include:

  * `UccChatWeb.RoomChannel` - responsible for pushing the new message
     out to all users with the channel open.
  * `UccChat.Robot` - responsible for passing the message to all active bots

  Private messages (only received by a single person) have special handling
  also. After the message is created and broadcast, it is deleted. So,
  these messages are single view and will not shown again when the user
  switches rooms or visits another channel.

  Since system messages can be generated while processing an create, they
  are not checked for permissions and channel state. Otherwise, we would
  create an infinite recursive loop.

  The message body is also scanned for @mentions, creating or deleting
  the appropriate user mentions and updating the direct message notifications.

  Finally, the sequential field is checked and set for each new message
  unless the field is set in the given message params.
  """
  def create(message) do
    channel_id = get_param message, :channel_id
    user_id = get_param message, :user_id

    user = Accounts.get_user user_id
    channel = Channel.get!(channel_id)

    message =
      if Channel.direct?(channel), do: Map.put(message, :type, "d"), else: message

    cond do
      message[:type] == "p" or message[:system] == true ->
        true

      Channel.user_muted? channel_id, user_id ->

        create_private_message(channel_id, user_id, message.body, system: false)
        create_private_message(channel_id, user_id, "You have been muted and cannot speak in this room")

      channel.read_only and not Permissions.has_permission?(user, "post-readonly", channel_id) ->
        create_private_message(channel_id, user_id,
          "You are not authorized to create a message")

      channel.archived ->
        create_private_message(channel_id, user_id,
          "You are not authorized to create a message")

      true ->
        true
    end
    |> case do
      true ->
        sequential_key =
          case Map.keys message do
            [first | _] when is_binary(first) -> "sequential"
            _ -> :sequential
          end
        {attachments_params, message_params} =
          message
          |> Map.put_new(sequential_key, sequential?(channel_id, user_id))
          |> Map.pop(:attachments, [])

        Multi.new
        |> Multi.insert(:message, __MODULE__.change(message_params))
        |> Multi.run(:attachments, &do_insert_attachments(&1, attachments_params))
        |> Repo.transaction()
        |> do_create()
      other ->
        other
    end
  end

  defp do_insert_attachments(%{message: %{id: id}}, attachments_params) do
    attachments_params
    |> Enum.reduce_while({:ok, []}, fn params, {:ok, acc} ->
      params
      |> Map.put("message_id", id)
      |> Attachment.create()
      |> case do
        {:ok, attachment}   -> {:cont, {:ok, [attachment | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp do_create({:ok, %{message: %{type: "p"} = message}}) do
    message = Repo.preload message, @preloads
    UccPubSub.broadcast "message:private", "user_id:" <> message.user_id, %{message: message}
    # use the repo directly so we bypass the notifications
    Repo.delete(message)
    {:ok, message}
  end

  defp do_create({:ok, %{message: message}}) do
    Mention.create_from_message(message)
    # Fetch the message again with the preloads so we pick up the new mentions.
    message = get(message.id, preload: @preloads)
    UccPubSub.broadcast "message:new", "channel:" <> message.channel_id, %{message: message, channel_name: message.channel.name}
    {:ok, message}
  end

  # return the standard 2 element tuple for message errors
  defp do_create({:error, :message, changeset}) do
    {:error, changeset}
  end

  # This will return {:error, :attachments, changeset}
  defp do_create(error) do
    error
  end

  defp sequential?(channel_id, user_id) do
    channel_id
    |> last_message()
    |> sequential_message?(user_id)
  end

  def update(message, attrs) do
    case super(message, attrs) do
      {:ok, message} ->
        # TODO: Need to handle update attachment description yet.
        Mention.update_from_message(message)
        # channel = Channel.get message.channel_id
        # Subscription.update_direct_notices channel.type, channel.id, message.user_id
        UccPubSub.broadcast "message:update", "channel:" <> message.channel_id, %{message: message}
        {:ok, message}
      error ->
        error
    end
  end

  def delete(message, %{user_roles: ur} = user) when is_list(ur) do
    if UccSettings.allow_message_deleting && (user.id == message.user_id ||
      Permissions.has_permission?(user, "delete-message", message.channel_id)) do

      message
      |> Repo.preload([:attachments])
      |> delete
      |> case do
        {:ok, _} = ok ->
          rebuild_sequentials(message)
          ok
        error ->
          error
      end
    else
      changeset =
        message
        |> change()
        |> Ecto.Changeset.add_error(:body, "Unauthorized",
          validation: :unauthorized)
      {:error, changeset}
    end
  end

  def delete(message, user_id) do
    delete message,
      Accounts.get_user(user_id,
        preload: [:account, :roles, user_roles: :role])
  end

  def delete(%{attachments: atts} = message) when is_list(atts) do

    case message |> change() |> Repo.delete do
      {:ok, _} ->
        UccPubSub.broadcast "message:delete", "channel:" <>
          message.channel_id, %{message: message}
        {:ok, message}
      error -> error
    end
  end

  def delete(message) do
    message
    |> Repo.preload([:attachments])
    |> delete
  end

  def delete!(message) do
    case delete(message) do
      {:ok, message} -> message
      error          -> raise inspect(error)
    end
  end

  def rebuild_sequentials(message) do
    spawn fn ->
      message.inserted_at
      |> get_by_later(message.channel_id)
      |> Enum.reduce({nil, nil}, fn message, acc ->
        case {acc, message} do
          {_, %{system: true}} ->
            {nil, nil}
          {{last_message, user_id}, %{user_id: user_id, sequential: false, inserted_at: inserted_at}} ->
            if sequential_message?(last_message, user_id, inserted_at) do
              __MODULE__.update message, %{sequential: true}
              Process.sleep(10)
            end
            {message, user_id}
          {{_, uid1}, %{user_id: user_id, sequential: true}} when uid1 != user_id ->
            __MODULE__.update message, %{sequential: false}
            Process.sleep(10)
            {message, user_id}
          {_, %{user_id: user_id}} ->
            {message, user_id}
        end
      end)
    end
  end

  def format_timestamp(%NaiveDateTime{} = dt) do
    {{yr, mo, day}, {hr, min, sec}} = NaiveDateTime.to_erl(dt)
    pad2(yr) <> pad2(mo) <> pad2(day) <> pad2(hr) <> pad2(min) <> pad2(sec)
  end

  def pad2(int), do: int |> to_string |> String.pad_leading(2, "0")

  def total_count do
    from m in @schema, select: count(m.id)
  end

  def get_total_count do
    Repo.one total_count()
  end

  def total_channels(type \\ 0) do
    from m in @schema,
      join: c in ChannelSchema, on: m.channel_id == c.id,
      where: c.type == ^type,
      select: count(m.id)
  end

  def get_total_channels do
    Repo.one total_channels()
  end

  def total_private do
    total_channels 1
  end

  def get_total_private do
    Repo.one total_private()
  end

  def total_direct do
    total_channels 2
  end

  def get_total_direct do
    Repo.one total_direct()
  end

  def get_room_messages(channel_id, %{id: user_id, tz_offset: tz}) do
    count =
      case Subscription.get(channel_id, user_id) do
        %{current_message: ""} -> 0
        %{current_message: cm} ->
          get_message_index(cm, channel_id)
        _ -> 0
      end

    count
    |> get_page_by_row(channel_id)
    |> new_days(tz || 0, [])
  end

  defp get_message_index(nil_or_empty, _channel_id) when nil_or_empty in ["", nil] do
    0
  end

  defp get_message_index(timestamp, channel_id) do
    @repo.one from m in @schema,
      where: m.channel_id == ^channel_id and m.timestamp <= ^timestamp,
      order_by: [asc: :inserted_at],
      select: count(m.id)
  end

  defp get_page_by_row(row, channel_id, opts \\ [])
  defp get_page_by_row(nil, channel_id, opts) do
    get_page_by_row(0, channel_id, opts)
  end

  defp get_page_by_row(row, channel_id, opts) do
    opts = Enum.into(opts, %{})
    page_size = opts[:page_size] || opts["page_size"] || AppConfig.page_size()
    (from m in @schema,
      where: m.channel_id == ^channel_id,
      order_by: [asc: :inserted_at],
      preload: ^@preloads)
    |> @repo.paginate(page_size: page_size, options: [row: row])
  end

  def get_surrounding_messages(channel_id, ts, user, opts \\ [])
  def get_surrounding_messages(channel_id, timestamp, user, opts) when timestamp in ["", nil] do
    get_messages channel_id, user, opts
  end

  def get_surrounding_messages(channel_id, timestamp, %{tz_offset: tz}, opts) do
    timestamp
    |> get_message_index(channel_id)
    |> get_page_by_row(channel_id, opts)
    |> new_days(tz || 0, [])
  end

  def get_messages(channel_id, %{tz_offset: tz}, opts \\ []) do
    preload = opts[:preload] || @preloads
    page = opts[:page] || [page_size: AppConfig.page_size()]

    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> preload(^preload)
    |> order_by([m], asc: m.inserted_at)
    |> @repo.paginate(page)
    |> new_days(tz || 0, [])
  end

  def search_messages(channel_id, %{tz_offset: tz}, pattern) do
    # The database handler will throw an exception if an invalid
    # query is entered. So, catch the exception here.
    try do
      pattern1 =
        case pattern do
          "/" <> _ = pattern ->
            pattern
          pattern ->
            String.split(pattern, " ", trim: true)
        end

      @schema
      |> where([m], m.channel_id == ^channel_id)
      |> pattern_clause(pattern1)
      |> Helpers.last_page
      |> preload(^@preloads)
      |> order_by([m], desc: m.inserted_at)
      |> @repo.all
      |> new_days(tz || 0, [])
    rescue
      _ ->
        []
    end
  end

  defp pattern_clause(query, "/" <> rest) do
    regex = String.trim_trailing rest, "/"
    where query, [m], fragment("? REGEXP ?", m.body, ^regex)
  end

  defp pattern_clause(query, []) do
    where query, false
  end

  defp pattern_clause(query, [word]) do
    where query, [m], like(fragment("lower(?)", m.body), ^("%" <> word <> "%"))
  end

  defp pattern_clause(query, [word1, word2]) do
    where query, [m], like(fragment("lower(?)", m.body), ^("%" <> word1 <> "%")) or
      like(fragment("lower(?)", m.body), ^("%" <> word2 <> "%"))
  end

  defp pattern_clause(query, words) do
    regex = Enum.join(words, "|")
    where query, [m], fragment("? REGEXP ?", m.body, ^regex)
  end

  defp new_days(%{entries: entries} = page, tz, list) do
    struct(page, entries: new_days(entries, tz, list))
  end

  defp new_days([h|t], tz, []), do: new_days(t, tz, [Map.put(h, :new_day, true)])
  defp new_days([h|t], tz, [last|_] = acc) do
    dt1 = Timex.shift(h.inserted_at, hours: tz)
    dt2 = Timex.shift(last.inserted_at, hours: tz)
    h = if Timex.day(dt1) == Timex.day(dt2) do
      h
    else
      Map.put(h, :new_day, true)
    end
    new_days t, tz, [h|acc]
  end
  defp new_days([], _, []), do: []
  defp new_days([], _, acc), do: Enum.reverse(acc)

  def last_message(channel_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> order_by([m], asc: m.inserted_at)
    |> last(:inserted_at)
    |> @repo.one
  end

  def last_user_id(channel_id) do
    case last_message channel_id do
      nil     -> nil
      %{user_id: user_id} -> user_id
    end
  end

  def first_message(channel_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> order_by([m], asc: m.inserted_at)
    |> first(:inserted_at)
    |> @repo.one
  end

  def get_user_ids(channel_id, user_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id and m.user_id != ^user_id)
    |> group_by([m], m.user_id)
    |> select([m], m.user_id)
    |> order_by([m], desc: m.inserted_at)
    |> @repo.all
  end
  def get_by_later(inserted_at, channel_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id and m.inserted_at > ^inserted_at)
    |> order_by(asc: :inserted_at)
    |> @repo.all
  end

  def sequential_message?(last_message, current_user_id, dt \\ Timex.now)
  def sequential_message?(nil, _, _), do: false
  def sequential_message?(last_message, current_user_id, dt) do
    current_user_id == last_message.user_id and
      Timex.after?(Timex.shift(last_message.inserted_at,
        seconds: UccSettings.grouping_period_seconds()), dt)
  end

end
