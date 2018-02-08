defmodule UccChat.Subscription do
  @moduledoc """
  Context module for the Subscription Schema.
  """
  use UccModel, schema: UccChat.Schema.Subscription

  alias UccChat.Schema.Channel
  alias UccChat.ChannelService

  require Logger

  def join_new(user_id, channel_id, opts \\ []) do
    with nil <- get_by(user_id: user_id, channel_id: channel_id),
         {:ok, subs} <-ChannelService.join_channel(channel_id, user_id) do
      subs
    else
      {:error, _} = error -> error
      subs -> subs
    end
    |> case do
      {:error, _} = error -> error
      subs ->
        if opts[:unread] do
          __MODULE__.update(subs, %{unread: subs.unread + 1})
        else
          {:ok, subs}
        end
    end
  end

  def update(channel_id, user_id, params) do
    case get(channel_id, user_id) do
      nil ->
        {:error, :not_found}
      sub ->
        __MODULE__.update(sub, params)
    end
  end

  def update(%@schema{} = schema, params) do
    super(schema, params)
  end

  def update(%{channel_id: channel_id, user_id: user_id}, params) do
     __MODULE__.update(channel_id, user_id, params)
  end

  def update_direct_notices(_type, _channel_id, _user_id) do
    Logger.warn "deprecated"
    nil
  end

  def get_all_for_channel(channel_id) do
    from c in @schema, where: c.channel_id == ^channel_id
  end

  def get_by_room(room, user_id) when is_binary(room) do
    @repo.one @schema.get_by_room room, user_id
  end

  def get(channel_id, user_id, opts \\ [])

  def get(channel_id, user_id, opts) when is_list(opts) do
    preload = opts[:preload] || []
    @repo.one from c in @schema, where: c.channel_id == ^channel_id and c.user_id == ^user_id,
      preload: ^preload
  end

  def get(channel_id, user_id, field) when is_atom(field) do
    channel_id
    |> get(user_id)
    |> Map.get(field)
  end

  def get_by_channel_id_and_not_user_id(channel_id, user_id, opts \\ []) do
    preload = opts[:preload] || []

    @schema
    |> where([s], s.channel_id == ^channel_id and s.user_id != ^user_id)
    |> preload(^preload)
    |> @repo.all
  end

  def get_by_channel_id_and_user_id(channel_id, user_id, opts \\ []) do
    preload = opts[:preload] || []

    @schema
    |> where([c], c.user_id == ^user_id and c.channel_id == ^channel_id)
    |> preload(^preload)
    |> @repo.one!
  end

  def open_channel_count(user_id) when is_binary(user_id) do
    @repo.one from s in @schema,
      where: s.open == true and s.user_id == ^user_id,
      select: count(s.id)
  end

  def open_channels(user_id) when is_binary(user_id) do
    @repo.all from s in @schema,
      join: c in Channel, on: s.channel_id == c.id,
      where: s.open == true and s.user_id == ^user_id,
      select: c
  end

  def get_by_user_and_type(user, type) do
    (from s in @schema,
      join: c in Channel, on: s.channel_id == c.id,
      where: c.type == ^type and s.user_id == ^(user.id),
      select: c)
    |> @repo.all
  end

  def get_by_user_id_and_types(user_id, types, opts \\ []) when is_list(types) do
    preload = opts[:preload] || []
    @schema
    |> where([cc], cc.user_id == ^user_id and cc.type in ^types)
    |> preload(^preload)
    |> @repo.all
  end

  def fuzzy_search(text, user_id, opts \\ []) do
    text
    |> String.to_charlist
    |> Enum.intersperse("%")
    |> to_string
    |> search(user_id, opts)
  end

  def search(text, user_id, _opts \\ []) do
    # preload = Keyword.put_new opts[:preload] || [], :channel
    match = "%" <> String.downcase(text) <> "%"
    (from s in @schema,
      join: c in Channel, on: s.channel_id == c.id,
      where: s.user_id == ^user_id and like(fragment("LOWER(?)", c.name), ^match),
      select: s, preload: [:channel])
    |> @repo.all
  end

  def update_all_hidden(channel_id, state) do
    @schema
    |> where([s], s.channel_id == ^channel_id)
    |> @repo.update_all(set: [hidden: state])
  end

  def get_by_user_id(user_id, opts \\ []) do
    preload = opts[:preload] || []
    @schema
    |> where(user_id: ^user_id)
    |> preload(^preload)
    |> @repo.all
  end

  def subscribed?(channel_id, user_id) do
    @schema
    |> where([s], s.channel_id == ^channel_id and s.user_id == ^user_id)
    |> @repo.all
    |> case do
      [] -> false
      _  -> true
    end
  end

  def get_unread(channel_id, user_id) do
    case get_by channel_id: channel_id, user_id: user_id do
      %{unread: unread} -> unread
      _ -> 0
    end
  end

  def clear_unread(channel_id, user_id) do
    channel_id
    |> set_unread(user_id, 0)
    |> set_has_unread(false)
  end

  def set_unread({:ok, subscription}, count) do
    __MODULE__.update(subscription, %{unread: count})
  end

  def set_unread(error, _count) do
    error
  end

  def set_unread(channel_id, user_id, 1) do
    channel_id
    |> set_has_unread(user_id, true)
    |> set_unread(1)
  end

  def set_unread(channel_id, user_id, count) do
    [channel_id: channel_id, user_id: user_id]
    |> get_by
    |> case do
      nil -> :error
      sub -> __MODULE__.update(sub, %{unread: count})
    end
  end

  def set_has_unread({:ok, subscription}, value) do
    __MODULE__.update(subscription, %{has_unread: value})
  end

  def set_has_unread(error, _value) do
    error
  end

  def set_has_unread(channel_id, user_id, false) do
    clear_unread(channel_id, user_id)
  end

  def set_has_unread(channel_id, user_id, count) do
    [channel_id: channel_id, user_id: user_id]
    |> get_by
    |> case do
      nil -> :error
      sub -> __MODULE__.update(sub, %{has_unread: count})
    end
  end

end
