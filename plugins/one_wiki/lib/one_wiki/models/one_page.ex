defmodule OneWiki.Page do
  @moduledoc """
  The Page context file.
  """
  use OneModel, schema: OneWiki.Schema.Page
  alias Ecto.Multi
  alias InfinityOne.Accounts.User

  require Logger

  def changeset(%User{} = user, params) do
    changeset %@schema{}, user, params
  end

  def changeset(%@schema{} = struct, %User{} = user) do
    changeset(struct, user, %{})
  end

  def changeset(struct, user, params) do
    struct
    |> @schema.changeset(params)
    |> validate_permission(user)
  end

  @doc """
  Create a new page.

  Creates the database entry for the page. Also creates a file with the page
  body in `priv/static/uploads/pages` directory. This directory is a git repo.
  After writing the file, it is committed to the git repo, providing version
  control of each page revision.
  """
  def create(user, params) do
    case create_transaction(user, params) |> @repo.transaction() do
      {:ok, %{insert: insert}} -> {:ok, insert}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp create_transaction(user, params) do
    Multi.new()
    |> Multi.run(:insert, fn _ -> run_insert(user, params) end)
    |> Multi.run(:create_file, &create_file(user, &1.insert))
  end

  defp run_insert(user, params) do
    user
    |> changeset(params)
    |> create
  end

  @doc """
  Updates an existing page.

  Updates the database record with the modified page. Runs the same git commands
  as create/2 to commit the revisions in git.
  """
  def update(user, page, params) do
    case update_transaction(user, page, params) |> @repo.transaction() do
      {:ok, %{update: update}} -> {:ok, update}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp update_transaction(user, page, params) do
    Multi.new()
    |> Multi.run(:update, fn _ -> run_update(user, page, params) end)
    |> Multi.run(:create_file, &create_file(user, &1.update, :updated))
  end

  defp run_update(user, page, params) do
    page
    |> changeset(user, params)
    |> __MODULE__.update()
  end

  defp create_file(user, page, action \\ :added) do
    contents = page.body
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

  def delete(user, id) do
    case delete_transaction(user, id) |> @repo.transaction() do
      {:ok, %{delete: delete}} -> {:ok, delete}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp delete_transaction(user, id) do
    Multi.new()
    |> Multi.run(:delete, fn _ -> run_delete(user, id) end)
    |> Multi.run(:delete_file, &delete_file(user, &1.delete))
  end

  defp run_delete(user, page_id) do
    page_id
    |> get()
    |> changeset(user)
    |> delete()
  end

  defp delete_file(user, page) do
    repo = Git.new OneWiki.pages_path()
    message = "'#{page.title}' delete by @#{user.username}"
    path = Path.join(OneWiki.pages_path(), page.id)
    with :ok <- File.rm(path),
         {:ok, _} <- Git.commit(repo, ["-am", message]) do
      {:ok, path}
    else
      {:error, error} -> {:error, error}
      other -> {:error, other}
    end
  end

  defp validate_permission(changeset, _user) do
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
