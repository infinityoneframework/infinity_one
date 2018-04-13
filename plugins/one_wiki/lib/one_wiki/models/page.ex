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
      {:ok, %{page: page}} -> {:ok, page}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp create_transaction(user, params) do
    changeset = changeset(user, params)
    Multi.new()
    |> Multi.insert(:page, changeset)
    |> Multi.run(:create_file, &create_file(user, &1.page, changeset))
  end

  @doc """
  Updates an existing page.

  Updates the database record with the modified page. Runs the same git commands
  as create/2 to commit the revisions in git.
  """
  def update(user, page, params) do
    case update_transaction(user, page, params) |> @repo.transaction() do
      {:ok, %{page: page}} -> {:ok, page}
      {:error, _, reason} -> {:error, reason}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  defp update_transaction(user, page, params) do
    changeset = changeset(page, user, params)
    Multi.new()
    |> Multi.update(:page, changeset)
    |> Multi.run(:update_file, &update_file(user, &1.page, changeset))
  end

  defp create_file(user, page, _changeset) do
    repo = Git.new OneWiki.pages_path()
    {path, message} = path_and_message(page, user, :added)
    with :ok <- File.write(path, page.body),
         {:ok, _} <- Git.add(repo, page.title),
         {:ok, _} <- Git.commit(repo, ["-m", message]) do
      {:ok, path}
    else
      true -> {:ok, path}
      {:error, error} -> {:error, error}
      other -> {:error, other}
    end
  end

  defp update_file(user, page, %{changes: %{title: _title} = changes} = changeset) do
    repo = Git.new OneWiki.pages_path()
    {path, message} = path_and_message(page, user, :renamed)
    old_path = Path.join(repo.path, changeset.data.title)
    old_name = changeset.data.title

    with :ok <- File.write(old_path, page.body),
         {:ok, _} <- Git.mv(repo, [old_name, page.title]),
         {:ok, _} <- Git.commit(repo, ["-am", message]) do
      {:ok, path}
    else
      true -> {:ok, path}
      {:error, error} -> {:error, error}
      other -> {:error, other}
    end
  end

  defp update_file(user, page, _changeset) do
    repo = Git.new OneWiki.pages_path()
    {path, message} = path_and_message(page, user, :changed)
    with :ok <- File.write(path, page.body),
         {:ok, status} <- Git.status(repo),
         false <- status =~ "nothing to commit",
         {:ok, _} <- Git.add(repo, page.title),
         {:ok, _} <- Git.commit(repo, ["-m", message]) do
      {:ok, path}
    else
      true -> {:ok, path}
      {:error, error} -> {:error, error}
      other -> {:error, other}
    end
  end

  defp path_and_message(page, user, action) do
    message = page.commit_message || "'#{page.title}' #{action} by @#{user.username}"
    path = Path.join(OneWiki.pages_path(), page.title)
    {path, message}
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

  def get_all_users(%@schema{} = page) do
    page
    |> @repo.preload([:users])
    |> Map.get(:users)
  end

  def get_all_page_online_users(%@schema{} = page) do
    page
    |> get_all_page_users()
    |> Enum.reject(&(&1.status == "offline"))
  end

  def get_all_page_users(%@schema{} = page) do
    page
    |> get_all_users()
    |> Enum.map(fn user ->
      user
      |> struct(status: OneChat.PresenceAgent.get(user.id))
      |> OneChat.Hooks.preload_user([])
    end)
  end

  def get_page_offline_users(page) do
    page
    |> get_all_page_users
    |> Enum.filter(&(&1.status == "offline"))
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
