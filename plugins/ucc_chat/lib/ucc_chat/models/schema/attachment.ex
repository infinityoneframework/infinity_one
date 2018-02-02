defmodule UccChat.Schema.Attachment do
  use UccChat.Shared, :schema
  use Arc.Ecto.Schema

  alias UccChat.Schema.{Channel, Message}
  alias UccChat.Settings.FileUpload

  schema "attachments" do
    field :file, UccChat.File.Type
    field :file_name, :string, default: ""
    field :description, :string, default: ""
    field :type, :string, default: ""
    field :size, :integer, default: 0
    belongs_to :channel, Channel
    belongs_to :message, Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:channel_id, :message_id, :file_name, :description,
      :type, :size])
    |> cast_attachments(params, [:file], allow_paths: true)
    |> validate_required([:file, :channel_id, :message_id])
    |> validate_quota(params)
  end

  def validate_quota(cs, params) do
    size =
      params["file"]
      |> Map.get(:path)
      |> File.lstat!
      |> Map.get(:size)
    if FileUpload.quota_check_success?(file_size_kb: size / 1024) do
      cs
    else
      add_error cs, :size, UcxUccWeb.Gettext.gettext("has exceeded storage quota")
    end
  end
end
