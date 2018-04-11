defmodule OneWiki.Page do
  @moduledoc """
  The Page context file.
  """
  use OneModel, schema: OneWiki.Schema.Page
  alias Ecto.Multi

  require Logger

  def changeset(user, params) do
    changeset %@schema{}, user, params
  end

  def changeset(struct, user, params) do
    struct
    |> @schema.changeset(params)
    |> validate_permission(user)
  end

  # def create(user, params) do
  #   user
  #   |> changeset(params)
  #   |> create
  # end
  def create(user, params) do
    case transaction(user, params) |> @repo.transaction() do
      {:ok, %{insert: insert}} -> {:ok, insert}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
    |> IO.inspect(label: "transaction result")
  end

  def transaction(user, params) do
    Multi.new()
    |> Multi.run(:insert, fn _ -> insert(user, params) end)
    |> Multi.run(:create_file, &create_file(user, &1.insert))
  end

  defp insert(user, params) do
    user
    |> changeset(params)
    |> create
  end

  defp create_file(user, page, action \\ :added) do
    Logger.warn "page: " <> inspect(page)
    contents = page.body
    # contents = "Title: " <> page.title <> "\n" <> page.body <> "\n"
    repo = Git.new OneWiki.pages_path()
    message = "'#{page.title}' #{action} by @#{user.username}"
    path = Path.join(OneWiki.pages_path(), page.id)
    with :ok <- File.write(path, contents),
         {:ok, _} <- Git.add(repo, page.id),
         {:ok, _} <- Git.commit(repo, ["-m", message]) do
      {:ok, path}
    else
      {:error, error} -> {:error, error}
      other -> {:error, other}
    end
  end

  def update(user, page, params) do
    case update_transaction(user, page, params) |> @repo.transaction() do
      {:ok, %{update: update}} -> {:ok, update}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
    |> IO.inspect(label: "transaction result")
  end

  defp update_transaction(user, page, params) do
    Multi.new()
    |> Multi.run(:update, fn _ -> __MODULE__.update(page, params) end)
    |> Multi.run(:create_file, &create_file(user, &1.update, :updated))
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

  def get_pages_by_pattern(user_id, pattern, count \\ 5)

  def get_pages_by_pattern(%{id: id}, pattern, count) do
    get_pages_by_pattern(id, pattern, count)
  end

  def get_pages_by_pattern(user_id, pattern, count) do
    user_id
    |> get_authorized_pages
    |> where([c], like(c.title, ^pattern))
    |> order_by([c], asc: c.title)
    |> limit(^count)
    |> select([c], {c.id, c.title})
    |> @repo.all
  end

  def get_all_pages_by_pattern(pattern, count \\ 8) do
    @schema
    |> where([c], like(fragment("LOWER(?)", c.title), ^pattern))
    |> where([c], c.type in [0, 1])
    |> order_by([c], asc: c.type)
    |> limit(^count)
    |> select([c], %{id: c.id, name: c.type})
    |> @repo.all
  end

  def get_authorized_pages(_) do
    list()
  end
end
