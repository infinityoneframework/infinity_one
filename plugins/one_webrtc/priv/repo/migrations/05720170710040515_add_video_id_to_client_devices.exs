defmodule OneWebrtc.Repo.Migrations.AddVideoIdToClientDevices do
  use Ecto.Migration

  def change do
    # create table(:client_devices, primary_key: false) do
    alter table(:client_devices) do
      add :video_input_id, :string
    end
  end
end
