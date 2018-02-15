defmodule UccChat.Schema.Mention do
  use UccChat.Shared, :schema
  alias UcxUcc.Accounts.User
  alias UccChat.Schema.{Message, Channel}
  alias UcxUcc.UccPubSub

  schema "mentions" do
    field :unread, :boolean, default: true
    field :all, :boolean, default: false
    field :name, :string

    belongs_to :user, User
    belongs_to :message, Message
    belongs_to :channel, Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(message_id channel_id)a

  def model, do: UccChat.Mention

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields ++ [:user_id, :unread, :all, :name])
    |> validate_required(@fields)
    |> prepare_changes(&prepare_notify/1)
  end

  defp prepare_notify(%{action: :insert} = changeset) do
    channel_id = changeset.changes[:channel_id]
    UccPubSub.broadcast "mention:insert", "channel:#{channel_id}",
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(%{action: :delete} = changeset) do
    channel_id = changeset.data.channel_id
    UccPubSub.broadcast "mention:delete", "channel:#{channel_id}" ,
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(changeset) do
    changeset
  end
end
