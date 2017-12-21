defmodule UccWebrtc.Settings.Schema.Webrtc do
  use UccSettings.Settings.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_webrtc" do
    field :webrtc_enable_channel, :boolean, default: false
    field :webrtc_enable_private, :boolean, default: true
    field :webrtc_enable_direct, :boolean, default: true
    field :webrtc_servers, :string,
      default: "stun:stun.l.google.com:19302, stun:stun.emetrotel.org:3478"
  end

  @fields [
    :webrtc_enable_channel, :webrtc_enable_private, :webrtc_enable_direct,
    :webrtc_servers,
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
