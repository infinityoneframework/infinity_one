defmodule UccChat.Schema.Notification do
  use UccChat.Shared, :schema

  alias UccChat.Schema.{Channel, AccountNotification, NotificationSetting}
  alias UcxUcc.Accounts.Account

  schema "notifications" do
    embeds_one :settings, NotificationSetting
    belongs_to :channel, Channel
    many_to_many :accounts, Account, join_through: AccountNotification

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:channel_id])
    |> cast_embed(:settings)
    |> validate_required([:settings, :channel_id])
  end

end
