defmodule InfinityOne.Repo.Migrations.AddFriendToDirects do
  use Ecto.Migration

  def up do
    alter table(:directs) do
      add :friend_id, references(:users, on_delete: :nilify_all, type: :binary_id)
    end
    create unique_index(:directs, [:user_id, :friend_id], name: :directs_user_id_friend_id_index)
    execute "DROP INDEX directs_user_id_users_index on directs"
  end

  def down do
    alter table(:accounts) do
      remove :friend_id
    end
  end
end
