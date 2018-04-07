defmodule InfinityOne.Settings.Schema.General do
  use OneSettings.Settings.Schema
  use Arc.Ecto.Schema

  @sitename InfinityOne.brandname()
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_general" do
    field :site_url, :string, default: "change-this"
    field :site_name, :string, default: @sitename
    field :enable_desktop_notifications, :boolean, default: true
    field :desktop_notification_duration, :integer, default: 8
    field :site_avatar, InfinityOne.SiteAvatar.Type
    field :site_client_name, :string, default: "use-host-name"
  end

  @fields [
    :site_url, :site_name, :enable_desktop_notifications,
    :desktop_notification_duration, :site_client_name
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> cast_attachments(params, [:site_avatar])
  end
end

