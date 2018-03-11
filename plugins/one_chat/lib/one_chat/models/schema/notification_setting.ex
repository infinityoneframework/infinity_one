defmodule OneChat.Schema.NotificationSetting do
  use OneChat.Shared, :schema

  embedded_schema do
    field :audio_mode, :string, default: "default"
    field :audio, :string, default: "system_default"
    field :desktop, :string, default: "default"
    field :duration, :integer, default: nil
    field :mobile, :string, default: "mentions"
    field :email, :string, default: "preferences"
    field :unread_alert, :string, default: "preferences"
  end

  @fields [
    :audio, :desktop, :duration, :mobile, :email, :unread_alert, :audio_mode
  ]

  def model, do: OneChat.NotificationSetting

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    # |> validate_required(@fields)
  end
end
