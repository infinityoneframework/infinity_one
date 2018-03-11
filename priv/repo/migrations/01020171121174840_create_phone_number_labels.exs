defmodule InfinityOne.Repo.Migrations.CreatePhoneNumberLabels do
  use Ecto.Migration

  def change do
    create table(:phone_number_labels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps(type: :naive_datetime)
    end
  end
end
