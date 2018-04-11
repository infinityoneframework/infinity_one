defmodule OneWiki.Schema.Subscription do
  @moduledoc """
  Schema and changesets for Subscription schema.

  """
  use OneChat.Shared, :schema

  alias InfinityOne.Accounts.User
  alias OneWiki.Schema.Page

  @module __MODULE__

  schema "wiki_subscriptions" do
    belongs_to :page, Page
    belongs_to :user, User
    field :type, :integer, default: 0
    field :alert, :boolean, default: false
    field :hidden, :boolean, default: false
    field :has_unread, :boolean, default: false
    field :ls, :utc_datetime
    field :f, :boolean, default: false          # favorite
    timestamps(type: :utc_datetime)
  end


  @fields ~w(page_id user_id)a
  @all_fields @fields ++ ~w(type alert ls f hidden has_unread)a

  def model, do: OneWiki.Subscription

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @all_fields)
    |> unique_constraint(:user_id, name: :wiki_subscriptions_user_id_page_id_index)
  end

  @doc """
  Get the query for retrieving all subscriptions for a given room id.
  """
  def get_all_for_page(page_id) do
    from c in @module, where: c.page_id == ^page_id
  end

  @doc """
  Get the query for subscriptions by page name and user id
  """
  def get_by_title(title, user_id) when is_binary(title) do
    from s in @module, join: p in Page, on: p.id == s.page_id,
      where: p.title == ^title and s.user_id == ^user_id
  end

  @doc """
  Get the query for subscriptions by page id and user id
  """
  def get(page_id, user_id) do
    from s in @module, where: s.page_id == ^page_id and s.user_id == ^user_id
  end

end
