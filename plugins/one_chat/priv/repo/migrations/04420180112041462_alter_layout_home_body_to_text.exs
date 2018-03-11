defmodule InfinityOne.Repo.Migrations.AlterLayoutHomeBodyToText do
  use Ecto.Migration

  def change do
    alter table(:settings_layout) do
      modify :content_home_body, :text
    end
  end
end
