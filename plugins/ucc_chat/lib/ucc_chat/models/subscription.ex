defmodule UccChat.Subscription do
  use UccModel, schema: UccChat.Schema.Subscription

  alias UccChat.Schema.Channel

  def get_all_for_channel(channel_id) do
    from c in @schema, where: c.channel_id == ^channel_id
  end

  def get_by_room(room, user_id) when is_binary(room) do
    @repo.one @schema.get_by_room room, user_id
  end

  def get(channel_id, user_id, opts \\ []) do
    preload = opts[:preload] || []
    from c in @schema, where: c.channel_id == ^channel_id and c.user_id == ^user_id,
      preload: ^preload
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
end
