defmodule UccWebrtc.Repo.Migrations.CreateClientDevices do
  use Ecto.Migration

  def change do
    # create table(:client_devices, primary_key: false) do
    create table(:client_devices) do
      # add :id, :binary_id, primary_key: true
      add :ip_addr, :integer
      add :handsfree_input_id, :string
      add :handsfree_output_id, :string
      add :headset_input_id, :string
      add :headset_output_id, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:client_devices, [:user_id])
  end
end
