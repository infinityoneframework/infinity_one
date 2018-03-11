defmodule InfinityOne.Repo.Migrations.CreateInfinityOne.Accounts.Role do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string
      add :scope, :string, default: "global"
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])
  end
end
