defmodule UcxUcc.Repo.Migrations.CreateUcxUcc.Accounts.Role do
  use Ecto.Migration

  def change do
    create table(:accounts_roles) do
      add :name, :string
      add :scope, :string, default: "global"
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts_roles, [:name])
  end
end
