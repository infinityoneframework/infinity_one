defmodule UccChat.Message do
  use UccModel, schema: UccChat.Schema.Message
  use Timex

  alias UcxUcc.Repo
  alias UccChat.Schema.Channel
  alias UccChat.{AppConfig, SubscriptionService}
  alias UccChat.ServiceHelpers, as: Helpers

  require Logger

  @preloads [:user, :edited_by, :attachments, :reactions]

  def preloads, do: @preloads

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
      join: c in Channel, on: m.channel_id == c.id,
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

  def get_surrounding_messages(channel_id, ts, user) when ts in ["", nil] do
    Logger.warn "ts: " <> "#{ts}"
    get_messages channel_id, user
  end
  def get_surrounding_messages(channel_id, timestamp, %{tz_offset: tz} = user) do
    Logger.warn "timestamp: " <> timestamp
    page_size = AppConfig.page_size()
    half_page = div page_size, 2

    message = @repo.one first((from m in @schema,
      where: m.timestamp <= ^timestamp and m.channel_id == ^channel_id,
        order_by: [asc: :inserted_at],
        limit: ^half_page), :inserted_at)

    Logger.warn "body: " <> message.timestamp <> " " <> message.body

    if message do
      # before_q = from m in @schema,
      #   where: m.inserted_at < ^(message.inserted_at) and m.channel_id == ^channel_id,
      #   order_by: [desc: :inserted_at],
      #   limit: 40,
      #   preload: ^@preloads
      (from m in @schema,
        where: m.inserted_at >= ^(message.inserted_at) and m.channel_id == ^channel_id,
        order_by: [asc: :inserted_at],
        limit: ^page_size,
        preload: ^@preloads)
      |> @repo.all
      |> new_days(tz || 0, [])

      # Enum.reverse(@repo.all(before_q)) ++ [message|@repo.all(after_q)]
      # |> new_days(tz || 0, [])
    else
      Logger.debug "did not find a message"
      get_messages(channel_id, user)
    end
  end

  def get_messages(channel_id, %{tz_offset: tz}) do
    Logger.warn ""
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> Helpers.last_page
    |> preload(^@preloads)
    |> order_by([m], asc: m.inserted_at)
    |> @repo.all
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

  def get_room_messages(channel_id, %{id: user_id} = user) do
    Logger.warn ""
    page_size = AppConfig.page_size()
    timestamp =
      case SubscriptionService.get(channel_id, user_id) do
        %{current_message: ""} -> nil
        %{current_message: cm} ->
          cnt1 = @repo.one from m in @schema,
            where: m.channel_id == ^channel_id and m.timestamp >= ^cm,
            select: count(m.id)
          if cnt1 > page_size, do: cm, else: nil
        _ -> nil
      end
    get_surrounding_messages(channel_id, timestamp, user)
  end

  def get_messsages_ge_ts(channel_id, user, ts) do
    Logger.warn "get_messsages_ge_ts is deprecated. Use next_page_by_ts/3 instead."
    next_page_by_ts(channel_id, user, ts)
  end

  def next_page_by_ts(channel_id, %{tz_offset: tz}, ts) do
    Logger.warn "ts: " <> "#{ts}"
    # before_q = from m in @schema,
    #   where: m.timestamp < ^ts,
    #   order_by: [desc: :inserted_at],
    #   limit: 25,
    #   preload: ^@preloads
    page_size = AppConfig.page_size()

    first =
      (from m in @schema,
        where: m.channel_id == ^channel_id and m.timestamp > ^ts,
        order_by: [asc: m.inserted_at],
        limit: 1)
      |> @repo.one

    (from m in @schema,
      where: m.channel_id == ^channel_id and m.inserted_at >= ^first.inserted_at,
      order_by: [asc: m.inserted_at],
      limit: ^page_size,
      preload: ^@preloads)
    |> @repo.all
    |> new_days(tz || 0, [])

    # Enum.reverse(@repo.all before_q) ++ @repo.all(after_q)
    # |> new_days(tz || 0, [])
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
    Logger.warn ""
    @schema
    |> where([m], m.channel_id == ^channel_id and m.inserted_at > ^inserted_at)
    |> order_by(asc: :inserted_at)
    |> @repo.all
  end
end
