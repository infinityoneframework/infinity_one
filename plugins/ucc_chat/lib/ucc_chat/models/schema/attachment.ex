defmodule UccChat.Schema.Attachment do
  @moduledoc """
  Schema and changesets for the Attachment model.
  """
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
    |> validate_required([:file, :channel_id])
    |> validate_quota(params)
  end

  def validate_quota(changeset, %{"file" => file}) do
    size =
      file
      |> Map.get(:path)
      |> File.lstat!
      |> Map.get(:size)
    if FileUpload.quota_check_success?(file_size_kb: size / 1024) do
      changeset
    else
      # TODO: Do we really want to use Gettext here?
      add_error changeset, :size, UcxUccWeb.Gettext.gettext("has exceeded storage quota")
    end
  end

  def validate_quota(changeset, _params) do
    changeset
  end
end
