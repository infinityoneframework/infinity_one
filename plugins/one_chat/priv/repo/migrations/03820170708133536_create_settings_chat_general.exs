defmodule InfinityOne.Repo.Migrations.CreateSettingsChatGeneral do
  use Ecto.Migration

  def change do
    create table(:settings_chat_general, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :enable_favorite_rooms, :boolean, default: true
      add :rooms_slash_commands, :string, default: ""
      add :chat_slash_commands, :string, default: ""
    end
  end
end
