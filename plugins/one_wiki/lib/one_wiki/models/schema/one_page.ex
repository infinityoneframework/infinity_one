defmodule OneWiki.Schema.Page do
  use OneChat.Shared, :schema

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
    belongs_to :parent, __MODULE__

    timestamps(type: :utc_datetime)
  end

  @required ~w(title body)a
  @fields ~w(type format parent_id)a ++ @required

  def model, do: OneWiki.Page

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@required)
  end
end
