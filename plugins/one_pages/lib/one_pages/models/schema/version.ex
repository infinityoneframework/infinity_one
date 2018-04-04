defmodule OnePages.Schema.Version do
  use OnePages.Shared, :schema

  schema "app_versions" do
    field :assets_url, :string
    field :body, :string
    field :draft, :boolean, default: false
    field :git_id, :integer
    field :html_url, :string
    field :name, :string
    field :prerelease, :boolean, default: false
    field :tag_name, :string
    field :url, :string

    has_many :assets, OnePages.Schema.Asset, on_replace: :delete

    timestamps()
  end

  def model, do: OnePages.Asset

  @doc false
  def changeset(verson, attrs \\ %{}) do
    verson
    |> cast(attrs, [:url, :assets_url, :html_url, :git_id, :tag_name, :name, :draft, :prerelease, :body])
    |> validate_required([:url, :assets_url, :html_url, :git_id, :tag_name, :name, :draft, :prerelease, :body])
    |> unique_constraint(:name)
    |> cast_assoc(:assets)
  end
end
