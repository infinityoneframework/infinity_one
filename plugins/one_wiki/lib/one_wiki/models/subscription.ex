defmodule OneWiki.Subscription do
  @moduledoc """
  Context module for the Subscription Schema.
  """
  use OneModel, schema: OneWiki.Schema.Subscription

  alias Ecto.Changeset

  alias OneWiki.Schema.Page
  alias InfinityOne.Accounts.User

  require Logger

  def update(page_id, user_id, params) do
    case get(page_id, user_id) do
      nil ->
        {:error, :not_found}
      sub ->
        __MODULE__.update(sub, params)
    end
  end

  def update(%@schema{} = schema, params) do
    super(schema, params)
  end

  def update(%{page_id: page_id, user_id: user_id}, params) do
     __MODULE__.update(page_id, user_id, params)
  end

  @doc """
  Delete a subscription given a user schema and page_id
  """
  def delete(%User{id: user_id}, page_id) do
    [user_id: user_id, page_id: page_id]
    |> get_by()
    |> __MODULE__.change()
    |> delete()
  end

  @doc """
  Hide a given user's page.
  """
  def hide_page(%{} = user, page_id) when is_binary(page_id) do
    update_page_hidden(user, page_id, true)
  end

  @doc """
  Make a given user's page visible.
  """
  def unhide_page(%{} = user, page_id) when is_binary(page_id) do
    update_page_hidden(user, page_id, false)
  end

  @doc """
  Set the hidden status for a given User's page.
  """
  def update_page_hidden(%{} = user, page_id, hidden \\ true) do
    with subscription <- get_by(page_id: page_id),
         false <- is_nil(subscription) do
      __MODULE__.update(subscription, %{hidden: hidden})
    end
  end

  def get_all_for_page(page_id, opts \\ []) do
    preload = opts[:preload] || []
    @repo.all from s in @schema,
      where: s.page_id == ^page_id,
      preload: ^preload
  end

  @doc """
  Get all the users for a given page.

  Returns a list of all users subscribed to the page given its id,
  with an option to scope the list by open or not open.

  ## Opts

  * :preload - The preload to be applied to the users list
  * :open - (true | false) filter on open or not open
  """
  def get_all_users_for_channel(channel_id, opts \\ []) do
    preload = opts[:preload] || []
    (from s in @schema,
      where: s.channel_id == ^channel_id,
      join: u in User,
      on: s.user_id == u.id,
      select: u)
    # |> select_open(opts[:open])
    |> @repo.all
    |> @repo.preload(preload)
  end

  # defp select_open(query, nil), do: query

  # defp select_open(query, open) do
  #   where query, [s], s.open == ^open
  # end

  @doc """
  Get all the open subscriptions for a given channel.

  """
  # def get_all_open_for_channel(channel_id, opts \\ []) do
  #   preload = opts[:preload] || []
  #   @repo.all from c in @schema,
  #     where: c.open == true and c.channel_id == ^channel_id,
  #     preload: ^preload
  # end

  # def get_by_title(title, user_id) when is_binary(title) do
  #   @repo.one @schema.get_by_title room, user_id
  # end

  def get(page_id, user_id, opts \\ [])

  def get(page_id, user_id, opts) when is_list(opts) do
    preload = opts[:preload] || []
    @repo.one from c in @schema, where: c.page_id == ^page_id and c.user_id == ^user_id,
      preload: ^preload
  end

  def get(page_id, user_id, field) when is_atom(field) do
    page_id
    |> get(user_id)
    |> case do
      nil   -> %{}
      other -> other
    end
    |> Map.get(field)
  end

  def get_by_page_id_and_not_user_id(page_id, user_id, opts \\ []) do
    preload = opts[:preload] || []

    @schema
    |> where([s], s.page_id == ^page_id and s.user_id != ^user_id)
    |> preload(^preload)
    |> @repo.all
  end

  def get_by_page_id_and_user_id(page_id, user_id, opts \\ []) do
    preload = opts[:preload] || []

    @schema
    |> where([c], c.user_id == ^user_id and c.page_id == ^page_id)
    |> preload(^preload)
    |> @repo.one!
  end

  def count(page_id) do
    @repo.one from s in @schema,
      where: s.page_id == ^page_id,
      select: count(s.id)
  end

  # def open_count(channel_id) do
  #   @repo.one from s in @schema,
  #     where: s.open == true and s.channel_id == ^channel_id,
  #     select: count(s.id)
  # end

  # def open_channel_count(user_id) when is_binary(user_id) do
  #   @repo.one from s in @schema,
  #     where: s.open == true and s.user_id == ^user_id,
  #     select: count(s.id)
  # end

  # def open_channels(user_id) when is_binary(user_id) do
  #   @repo.all from s in @schema,
  #     join: c in Channel, on: s.channel_id == c.id,
  #     where: s.open == true and s.user_id == ^user_id,
  #     select: c
  # end

  # def open?(channel_id, user_id) do
  #   !! @repo.one(from(s in @schema, where: s.channel_id == ^channel_id and s.user_id == ^user_id, select: s.open))
  # end

  def get_by_user_and_type(user, type) do
    (from s in @schema,
      join: p in Page, on: s.page_id == p.id,
      where: p.type == ^type and s.user_id == ^(user.id),
      select: p)
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
      join: p in Page, on: s.page_id == p.id,
      where: s.user_id == ^user_id and like(fragment("LOWER(?)", p.title), ^match),
      select: s, preload: [:page])
    |> @repo.all
  end

  def update_all_hidden(page_id, state) do
    @schema
    |> where([s], s.page_id == ^page_id)
    |> @repo.update_all(set: [hidden: state])
  end

  def get_by_user_id(user_id, opts \\ []) do
    preload = opts[:preload] || []
    @schema
    |> where(user_id: ^user_id)
    |> preload(^preload)
    |> @repo.all
  end

  def subscribed?(page_id, user_id) do
    @schema
    |> where([s], s.page_id == ^page_id and s.user_id == ^user_id)
    |> @repo.all
    |> case do
      [] -> false
      _  -> true
    end
  end

  # def get_unread(channel_id, user_id) do
  #   case get_by channel_id: channel_id, user_id: user_id do
  #     %{unread: unread} -> unread
  #     _ -> 0
  #   end
  # end

  def clear_unread(page_id, user_id) do
    page_id
    # |> set_unread(user_id, 0)
    |> set_has_unread(false)
  end

  # def inc_unread(channel_id, user_id) do
  #   from(s in @schema, where: s.channel_id == ^channel_id and s.user_id == ^user_id)
  #   |> @repo.update_all(inc: [unread: 1])
  # end

  # def set_unread({:ok, subscription}, count) do
  #   __MODULE__.update(subscription, %{unread: count})
  # end

  # def set_unread(error, _count) do
  #   error
  # end

  # def set_unread(channel_id, user_id, 1) do
  #   channel_id
  #   |> set_has_unread(user_id, true)
  #   |> set_unread(1)
  # end

  # def set_unread(channel_id, user_id, count) do
  #   [channel_id: channel_id, user_id: user_id]
  #   |> get_by
  #   |> case do
  #     nil -> :error
  #     sub -> __MODULE__.update(sub, %{unread: count})
  #   end
  # end

  def set_has_unread({:ok, subscription}, value) do
    __MODULE__.update(subscription, %{has_unread: value})
  end

  def set_has_unread(error, _value) do
    error
  end

  def set_has_unread(page_id, user_id, false) do
    clear_unread(page_id, user_id)
  end

  def set_has_unread(page_id, user_id, count) do
    [page_id: page_id, user_id: user_id]
    |> get_by
    |> case do
      nil -> :error
      sub -> __MODULE__.update(sub, %{has_unread: count})
    end
  end

  def usernames_by_page_id(page_id) do
    @repo.all from s in @schema,
      join: u in User,
      on: s.user_id == u.id,
      where: s.page_id == ^page_id,
      select: u.username
  end

  # def close_opens(user_id) do
  #   from(s in @schema,
  #     where: s.user_id == ^user_id,
  #     update: [set: [open: false]])
  #   |> @repo.update_all([])
  # end

  # def open(channel_id, user_id) do
  #   close_opens(user_id)
  #   __MODULE__.update channel_id, user_id, %{open: true}
  # end

  # def update_message_action("insert", payload) do
  #   channel = OneChat.Channel.get payload.channel_id

  #   channel.id
  #   |> get_by_channel_id_and_not_user_id(payload.user_id)
  #   |> update_message_subsciptions(payload[:type], channel.nway)
  # end

  # def update_message_action("update", payload) do
  #   channel = OneChat.Channel.get payload.channel_id

  #   channel.id
  #   |> get_by_channel_id_and_not_user_id(payload.edited_id)
  #   |> update_message_subsciptions(payload[:type], channel.nway)
  # end

  # def update_message_action(_action, _payload), do: :ok

  # defp update_message_subsciptions(subscriptions, type, nway) when type == "d" or nway do
  #   Enum.each(subscriptions, fn subscription ->
  #     if !subscription.open do
  #       update!(subscription, %{has_unread: true, unread: subscription.unread + 1})
  #     end
  #   end)
  # end

  # defp update_message_subsciptions(subscriptions, _type, _nway) do
  #   Enum.each(subscriptions, fn subscription ->
  #     if !subscription.open do
  #       update!(subscription, %{has_unread: true})
  #     end
  #   end)
  # end
end
