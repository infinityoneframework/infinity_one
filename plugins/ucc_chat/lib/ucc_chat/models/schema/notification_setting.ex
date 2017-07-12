defmodule UccChat.Schema.NotificationSetting do
  use UccChat.Shared, :schema

  embedded_schema do
    field :audio, :string, default: "system_default"
    field :desktop, :string, default: "mentions"
    field :duration, :integer, default: nil
    field :mobile, :string, default: "mentions"
    field :email, :string, default: "preferences"
    field :unread_alert, :string, default: "preferences"
  end

  @fields [
    :audio, :desktop, :duration, :mobile, :email, :unread_alert
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    # |> validate_required(@fields)
  end
end
