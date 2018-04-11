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

  def get_subscribed_for_user(user) do
    user
    |> @schema.subscribed_pages_query()
    |> @repo.all()
  end

  def get_visible_subscribed_for_user(user) do
    user
    |> @schema.subscribed_pages_query()
    |> where([p, s], s.hidden == false)
    |> @repo.all()
  end
end
