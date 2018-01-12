defmodule UcxUcc.Repo.Migrations.AddUniqueIndexToStarredMessage do
  use Ecto.Migration

  def change do

    create unique_index(:starred_messages, [:user_id, :channel_id, :message_id],
      name: :starred_messages_user_id_channel_id_message_id)
  end
end
