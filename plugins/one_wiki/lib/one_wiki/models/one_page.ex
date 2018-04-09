defmodule OneWiki.Page do
  use OneModel, schema: OneWiki.Schema.Page

  def changeset(user, params) do
    changeset %@schema{}, user, params
  end

  def changeset(struct, user, params) do
    struct
    |> @schema.changeset(params)
    |> validate_permission(user)
  end

  def create(user, params) do
    user
    |> changeset(params)
    |> create
  end

  def validate_permission(changeset, _user) do
    changeset
  end

end
