defmodule OneChat.Schema.Mention do
  use OneChat.Shared, :schema
  alias InfinityOne.Accounts.User
  alias OneChat.Schema.{Message, Channel}
  alias InfinityOne.OnePubSub

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

  def model, do: OneChat.Mention

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
    OnePubSub.broadcast "mention:insert", "channel:#{channel_id}",
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(%{action: :delete} = changeset) do
    channel_id = changeset.data.channel_id
    OnePubSub.broadcast "mention:delete", "channel:#{channel_id}" ,
      %{channel_id: channel_id}
    changeset
  end

  defp prepare_notify(changeset) do
    changeset
  end
end
