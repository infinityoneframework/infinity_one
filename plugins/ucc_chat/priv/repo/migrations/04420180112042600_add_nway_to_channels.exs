defmodule UcxUcc.Repo.Migrations.AddNwayToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :nway, :boolean, default: :false
    end
  end
end
