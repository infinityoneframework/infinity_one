defmodule InfinityOne.Repo.Migrations.AddUniqueIndexToPinndMessage do
  use Ecto.Migration

  def change do
    create unique_index(:pinned_messages, [:channel_id, :message_id],
      name: :pinned_messages_channel_id_message_id)
  end
end
