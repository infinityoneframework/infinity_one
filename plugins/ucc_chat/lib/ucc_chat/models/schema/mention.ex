defmodule UccChat.Schema.Mention do
  use UccChat.Shared, :schema
  alias UcxUcc.Accounts.User
  alias UccChat.Schema.{Message, Channel}

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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields ++ [:user_id, :unread, :all, :name])
    |> validate_required(@fields)
  end

end
