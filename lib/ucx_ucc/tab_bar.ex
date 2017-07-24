defmodule UcxUcc.TabBar do
  @moduledoc """
  Manage the TabBar data store.

  Manages the the data store for buttons and ftab state.
  """
  @name :tabbar

  @doc """
  Initialize the TabBar data store.
  """
  def initialize do
    :ets.new @name, [:public, :named_table]
  end

  @doc """
  Insert an entry into the data store
  """
  def insert(key, value) do
    :ets.insert @name, {key, value}
  end

  @doc """
  Lookup a value from the data store
  """
  def lookup(key) do
    :ets.lookup @name, key
  end

  @doc """
  Add a button to the button store

  ## Examples

      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      true
  """
  def add_button(config) do
    insert {:button, config.id}, config
  end

  @doc """
  Get a button from the button store

  ## Examples

      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.get_button "one"
      %{id: "one", name: "B1"}
  """
  def get_button(key) do
    case lookup {:button, key} do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc """
  Get a button from the button store

  ## Examples

      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.get_button! "one"
      %{id: "one", name: "B1"}
  """
  def get_button!(key) do
    get_button(key) || raise("invalid button #{key}")
  end

  @doc """
  Get all buttons from the button store

  ## Examples

      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.get_buttons
      [%{id: "one", name: "B1"}]
  """
  def get_buttons() do
    @name
    |> :ets.match({{:button, :"_"}, :"$2"})
    |> List.flatten
    |> Enum.sort(& &1.order < &2.order)
  end

  @doc """
  Add a ftab from the ftab store

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      true
  """
  def open_ftab(user_id, channel_id, name, view) do
    insert {:ftab, {user_id, channel_id}}, {name, view}
  end

  @doc """
  Get a ftab from the ftab store

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.get_ftab 1, 2
      {"test", nil}

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", %{one: 1}
      iex> UcxUcc.TabBar.get_ftab 1, 2
      {"test", %{one: 1}}
  """
  def get_ftab(user_id, channel_id) do
    case lookup {:ftab, {user_id, channel_id}} do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc """
  Close a ftab

  Removes the ftab entry

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.get_ftab 1, 2
      {"test", nil}
      iex> UcxUcc.TabBar.close_ftab 1, 2
      iex> UcxUcc.TabBar.get_ftab 1, 2
      nil

  """
  def close_ftab(user_id, channel_id) do
    :ets.delete @name, {:ftab, {user_id, channel_id}}
  end

  @doc """
  Get all ftabs

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> UcxUcc.TabBar.get_ftabs |> Enum.sort
      [[{1, 2}, {"test", nil}], [{1, 3}, {"other", %{one: 1}}]]

  """
  def get_ftabs() do
    :ets.match(@name, {{:ftab, :"$1"}, :"$2"})
  end

  @doc """
  Get all tabs for a given user.

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> UcxUcc.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> UcxUcc.TabBar.get_ftabs(1) |> Enum.sort
      [{"other", %{one: 1}}, {"test", nil}]
  """
  def get_ftabs(user_id) do
    @name
    |> :ets.match({{:ftab, {user_id, :"_"}}, :"$2"})
    |> List.flatten
  end

  @doc """
  Close all ftabs for a given user.

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> UcxUcc.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> UcxUcc.TabBar.close_user_ftabs 1
      iex> UcxUcc.TabBar.get_ftabs
      [[{2, 3}, {"other", %{one: 2}}]]

  """
  def close_user_ftabs(user_id) do
    :ets.match_delete @name, {{:ftab, {user_id, :"_"}}, :"_"}
  end

  @doc """
  Close all ftabs for a given channel.

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> UcxUcc.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> UcxUcc.TabBar.close_channel_ftabs 3
      iex> UcxUcc.TabBar.get_ftabs
      [[{1, 2}, {"test", nil}]]

  """
  def close_channel_ftabs(channel_id) do
    :ets.match_delete @name, {{:ftab, {:"_", channel_id}}, :"_"}
  end

  @doc """
  Delete all ftabs

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> UcxUcc.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.delete_ftabs
      iex> UcxUcc.TabBar.get_ftabs
      []
      iex> UcxUcc.TabBar.get_buttons
      [%{id: "one", name: "B1"}]
  """
  def delete_ftabs do
    :ets.match_delete(@name, {{:ftab, :"_"}, :"_"})
  end

  @doc """
  Delete all ftabs

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.add_button %{id: "two", name: "B2"}
      iex> UcxUcc.TabBar.delete_buttons
      iex> UcxUcc.TabBar.get_buttons
      []
      iex> UcxUcc.TabBar.get_ftabs
      [[{1, 2}, {"test", nil}]]
  """
  def delete_buttons do
    :ets.match_delete(@name, {{:button, :"_"}, :"_"})
  end

  @doc """
  Get all entries

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.add_button %{id: "two", name: "B2"}
      iex> UcxUcc.TabBar.get_all |> Enum.sort
      [[{{:button, "one"}, %{id: "one", name: "B1"}}],
      [{{:button, "two"}, %{id: "two", name: "B2"}}],
      [{{:ftab, {1, 2}}, {"test", nil}}]]
  """
  def get_all do
    :ets.match @name, :"$1"
  end

  @doc """
  Delete all entries

  ## Examples

      iex> UcxUcc.TabBar.open_ftab 1, 2, "test", nil
      iex> UcxUcc.TabBar.add_button %{id: "one", name: "B1"}
      iex> UcxUcc.TabBar.add_button %{id: "two", name: "B2"}
      iex> UcxUcc.TabBar.delete_all
      iex> UcxUcc.TabBar.get_all
      []
  """
  def delete_all do
    :ets.match_delete @name, :"$1"
  end


end
