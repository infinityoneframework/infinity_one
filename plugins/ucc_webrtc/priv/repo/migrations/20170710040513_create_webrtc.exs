defmodule UccWebrtc.Repo.Migrations.CreateWebrtc do
  use Ecto.Migration

  def change do
    create table(:settings_webrtc, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :webrtc_enable_channel, :boolean, default: false
      add :webrtc_enable_private, :boolean, default: true
      add :webrtc_enable_direct, :boolean, default: true
      add :webrtc_servers, :string,
        default: "stun:stun.l.google.com:19302, stun:23.21.150.121"
    end
  end
end
