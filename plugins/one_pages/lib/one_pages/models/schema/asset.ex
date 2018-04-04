defmodule OnePages.Schema.Asset do
  use OnePages.Shared, :schema

  alias OnePages.Schema

  schema "app_assets" do
    field :browser_download_url, :string
    field :content_type, :string
    field :download_count, :integer
    field :git_id, :integer
    field :name, :string
    field :state, :string
    field :url, :string

    belongs_to :version, Schema.Version, on_replace: :delete

    timestamps()
  end

  def model, do: OnePages.Asset

  @doc false
  def changeset(asset, attrs \\ %{}) do
    asset
    |> cast(attrs, [:url, :git_id, :version_id, :name, :content_type, :state, :download_count, :browser_download_url])
    |> validate_required([:url, :git_id, :name, :content_type, :state, :download_count, :browser_download_url])
  end
end
