defmodule OneWiki.Schema.Page do
  use OneChat.Shared, :schema

  alias InfinityOne.Accounts.User

  @formats ~w(markdown html)
  @types %{
    0 => "topic",
    1 => "private",
    2 => "draft"
  }

  schema "wiki_pages" do
    field :title, :string
    field :body, :string
    field :type, :integer, default: 0
    field :format, :string, default: "markdown"
    field :commit_message, :string
    field :commit, :string
    field :draft, :boolean, default: false

    belongs_to :parent, __MODULE__
    has_many :subscriptions, OneWiki.Schema.Subscription
    many_to_many :users, User, join_through: OneWiki.Schema.Subscription

    timestamps(type: :utc_datetime)
  end

  @required ~w(title body)a
  # @fields ~w(type format parent_id)a ++ @required
  @fields ~w(type format parent_id commit commit_message draft)a ++ @required

  def model, do: OneWiki.Page

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@required)
  end

  def subscribed_pages_query(user) do
    from p in __MODULE__,
      join: s in OneWiki.Schema.Subscription,
      on: s.page_id == p.id,
      where: s.user_id == ^user.id,
      select: p,
      order_by: [asc: p.title]
  end
end
