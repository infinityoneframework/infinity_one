defmodule UccChat.Schema.StarredMessage do
  use UccChat.Shared, :schema

  alias UcxUcc.Accounts.User
  alias UccChat.Schema.{Message, Channel}

  schema "starred_messages" do
    belongs_to :user, User
    belongs_to :message, Message
    belongs_to :channel, Channel

    timestamps(type: :utc_datetime)
  end

  @fields ~w(user_id message_id channel_id)a

  def model, do: UccChat.StarredMessage

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:user_id, name: :starred_messages_user_id_channel_id_message_id)
  end
end
