defmodule UccChat.Attachment do
  use UccChat.Shared, :schema
  use Arc.Ecto.Schema

  schema "attachments" do
    field :file, UccChat.File.Type
    field :file_name, :string, default: ""
    field :description, :string, default: ""
    field :type, :string, default: ""
    field :size, :integer, default: 0
    belongs_to :channel, UccChat.Channel
    belongs_to :message, UccChat.Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:channel_id, :message_id, :file_name, :description, :type, :size])
    |> cast_attachments(params, [:file])
    |> validate_required([:file, :channel_id, :message_id])
  end

end
