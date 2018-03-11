defmodule InfinityOne.Repo.Migrations.AddStatusMessageToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :status_message, :string, default: ""
      add :status_message_history, :string, default: ""
    end
  end
end
