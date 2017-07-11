defmodule UccChat.Message do
  use UccModel, schema: UccChat.Schema.Message
  use Timex

  alias UccChat.Schema.Channel

  alias UccChat.{AppConfig, SubscriptionService,}
  #   TypingAgent, Mention, Subscription,
  #   Web.MessageView, ChatDat, Channel, ChannelService, Web.UserChannel,
  #   MessageAgent, AttachmentService
  # }
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

  def total_channels(type \\ 0) do
    from m in @schema,
      join: c in Channel, on: m.channel_id == c.id,
      where: c.type == ^type,
      select: count(m.id)
  end

  def total_private do
    total_channels 1
  end

  def total_direct do
    total_channels 2
  end

  def get_surrounding_messages(channel_id, "", user) do
    get_messages channel_id, user
  end
  def get_surrounding_messages(channel_id, timestamp, %{tz_offset: tz} = user) do
    message = @repo.one from m in @schema,
      where: m.timestamp == ^timestamp and m.channel_id == ^channel_id,
      preload: ^@preloads
    if message do
      before_q = from m in @schema,
        where: m.inserted_at < ^(message.inserted_at) and m.channel_id == ^channel_id,
        order_by: [desc: :inserted_at],
        limit: 50,
        preload: ^@preloads
      after_q = from m in @schema,
        where: m.inserted_at > ^(message.inserted_at) and m.channel_id == ^channel_id,
        limit: 50,
        preload: ^@preloads

      Enum.reverse(@repo.all(before_q)) ++ [message|@repo.all(after_q)]
      |> new_days(tz || 0, [])
    else
      Logger.warn "did not find a message"
      get_messages(channel_id, user)
    end
  end

  def get_messages(channel_id, %{tz_offset: tz}) do
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> Helpers.last_page
    |> preload(^@preloads)
    |> order_by([m], asc: m.inserted_at)
    |> @repo.all
    |> new_days(tz || 0, [])
  end

  def get_room_messages(channel_id, %{id: user_id} = user) do
    page_size = AppConfig.page_size()
    case SubscriptionService.get(channel_id, user_id) do
      %{current_message: ""} -> nil
      %{current_message: cm} ->
        cnt1 = @repo.one from m in @schema,
          where: m.channel_id == ^channel_id and m.timestamp >= ^cm,
          select: count(m.id)
        if cnt1 > page_size, do: cm, else: nil
      _ -> nil
    end
    |> case do
      nil ->
        get_messages(channel_id, user)
      ts ->
        get_messsages_ge_ts(channel_id, user, ts)
    end
  end

  def get_messsages_ge_ts(channel_id, %{tz_offset: tz}, ts) do
    before_q = from m in @schema,
      where: m.timestamp < ^ts,
      order_by: [desc: :inserted_at],
      limit: 25,
      preload: ^@preloads

    after_q = from m in @schema,
      where: m.channel_id == ^channel_id and m.timestamp >= ^ts,
      preload: ^@preloads

    Enum.reverse(@repo.all before_q) ++ @repo.all(after_q)
    |> new_days(tz || 0, [])
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
    |> last
    |> @repo.one
  end

  def first_message(channel_id) do
    @schema
    |> where([m], m.channel_id == ^channel_id)
    |> order_by([m], asc: m.inserted_at)
    |> first
    |> @repo.one
  end

end
