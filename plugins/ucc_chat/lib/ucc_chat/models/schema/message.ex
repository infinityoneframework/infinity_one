defmodule UccChat.Schema.Message do
  @moduledoc """
  Schema and changesets for the Message schema.
  """
  use UccChat.Shared, :schema

  import Ecto.Changeset

  alias UcxUcc.{Accounts.User, UccPubSub}
  alias UccChat.Schema.{Mention, Channel, Reaction, Attachment, StarredMessage}

  require Logger

  schema "messages" do
    field :body, :string
    field :sequential, :boolean, default: false
    field :timestamp, :string
    field :type, :string, default: ""
    field :expire_at, :utc_datetime
    field :system, :boolean, default: false

    belongs_to :user, User
    belongs_to :channel, Channel
    belongs_to :edited_by, User, foreign_key: :edited_id

    has_many :stars, StarredMessage, on_delete: :delete_all
    has_many :attachments, Attachment, on_delete: :delete_all
    has_many :reactions, Reaction, on_delete: :delete_all
    has_many :mentions, Mention, on_delete: :delete_all

    field :is_groupable, :boolean, virtual: true
    field :t, :string, virtual: true
    field :own, :boolean, virtual: true
    field :is_temp, :boolean, virtual: true
    field :chat_opts, :boolean, virtual: true
    field :custom_class, :string, virtual: true
    field :avatar, :string, virtual: true
    field :new_day, :boolean, default: false, virtual: true
    field :first_unread, :boolean, default: false, virtual: true

    timestamps(type: :utc_datetime)
  end

  @fields [
    :body, :user_id, :channel_id, :sequential, :timestamp, :edited_id,
    :type, :expire_at, :system, :inserted_at
  ]
  @required [:user_id]

  def model, do: UccChat.Message

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@required)
    |> add_timestamp
    |> prepare_changes(&delete_attachment_files/1)
    |> prepare_changes(&update_subscriptions/1)
  end

  @doc """
  Create the string time stamp and add to changes.

  The time stamp is a string representation of the inserted at date with
  millisecond precision. Only generate it for create requests.
  """
  def add_timestamp(%{data: %{timestamp: nil}} = changeset) do
    put_change(changeset, :timestamp, UccChat.ServiceHelpers.get_timestamp())
  end

  def add_timestamp(changeset) do
    changeset
  end

  defp update_subscriptions(%{action: :insert, changes: changes} = changeset) do
    UccPubSub.broadcast "subscription:update", "message:insert",
      %{
        channel_id: changes.channel_id,
        user_id: changes.user_id,
        type: changes[:type]
      }

    changeset
  end

  defp update_subscriptions(%{action: :update, changes: changes, data: data} = changeset) do
    UccPubSub.broadcast "subscription:update", "message:insert",
      %{
        channel_id: data.channel_id,
        user_id: data.user_id,
        type: data.type,
        edited_id: changes[:edited_id]
      }
    changeset
  end

  defp update_subscriptions(%{} = changeset), do: changeset

  # Handle deleting the uploads folder containing the attachments for
  # the given deleted message
  defp delete_attachment_files(%{action: :delete} = changeset) do
    Enum.each changeset.data.attachments, fn attachment ->
      {attachment.file, attachment}
      |> UccChat.File.url()
      |> String.replace(~r{/[^/]+$}, "")
      |> String.trim_leading("/")
      |> File.rm_rf!()
    end
    changeset
  end

  # Do nothing if this is not a delete
  defp delete_attachment_files(changeset) do
    changeset
  end
end
