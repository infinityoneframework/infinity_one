defmodule OneSettings.Repo.Migrations.CreateOneSettings.Settings.Config do
  use Ecto.Migration

  def change do
    create table(:settings_configs) do
      add :name, :string
      add :scope, :string
      add :type, :string
      add :value, :string
      add :default, :string

      timestamps()
    end

  end
end
