defmodule OneWiki.Settings.Schema.Wiki do
  use OneSettings.Settings.Schema
  use InfinityOneWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_wiki" do
    field :wiki_enabled, :boolean, default: false
    field :wiki_side_nav_title, :string, default: gettext("Pages")
    field :wiki_history_enabled, :boolean, default: false
    field :wiki_languages, :string, default: "markdown"
    field :wiki_default_language, :string, default: "markdown"
    field :wiki_storage_path, :string, default: "priv/static/uploads/pages"
  end

  @fields [
    :wiki_enabled,
    :wiki_side_nav_title,
    :wiki_history_enabled,
    :wiki_languages,
    :wiki_default_language,
    :wiki_storage_path
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end
