defmodule UcxUcc.Repo.Migrations.CreatePhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:phone_numbers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :primary, :boolean, default: false, null: false
      add :type, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :label_id, references(:phone_number_labels, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :naive_datetime)
    end

    create index(:phone_numbers, [:user_id])
    create index(:phone_numbers, [:label_id])
  end
end
