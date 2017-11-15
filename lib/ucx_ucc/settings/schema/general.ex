defmodule UcxUcc.Settings.Schema.General do
  use UccSettings.Settings.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_general" do
    field :site_url, :string, default: "change-this"
    field :site_name, :string, default: "UccChat"
    field :enable_desktop_notifications, :boolean, default: true
    field :desktop_notification_duration, :integer, default: 8
  end

  @fields [
    :site_url, :site_name, :enable_desktop_notifications,
    :desktop_notification_duration
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end

