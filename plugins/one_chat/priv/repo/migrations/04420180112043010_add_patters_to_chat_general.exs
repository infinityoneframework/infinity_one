defmodule InfinityOne.Repo.Migrations.AddPatternsToChatGeneral do
  use Ecto.Migration

  def change do
    alter table(:settings_chat_general) do
      add :message_replacement_patterns, :text
    end
  end
end
