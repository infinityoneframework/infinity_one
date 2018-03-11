defmodule InfinityOne.Repo.Migrations.CreateInfinityOne.Permissions.Permission do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
    end

    create unique_index(:permissions, [:name])
  end
end
