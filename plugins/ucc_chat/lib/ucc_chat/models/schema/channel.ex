defmodule UccChat.Schema.Channel do
  use UccChat.Shared, :schema

  alias UccChat.Schema.{
    Message, Subscription, Attachment, StaredMessage, Notification
  }
  alias UcxUcc.Accounts.User

  require Logger

  schema "channels" do
    field :name, :string
    field :topic, :string
    field :type, :integer, default: 0
    field :read_only, :boolean, default: false
    field :archived, :boolean, default: false
    field :blocked, :boolean, default: false
    field :active, :boolean, default: true
    field :default, :boolean, default: false
    field :description, :string
    has_many :subscriptions, Subscription, on_delete: :delete_all
    has_many :users, through: [:subscriptions, :user], on_delete: :nilify_all
    has_many :stared_messages, StaredMessage, on_delete: :delete_all
    has_many :messages, Message, on_delete: :delete_all
    has_many :notifications, Notification, on_delete: :delete_all
    has_many :attachments, Attachment, on_delete: :delete_all

    belongs_to :owner, User, foreign_key: :user_id

    timestamps(type: :utc_datetime)
  end

  @fields ~w(archived name type topic read_only blocked default user_id description active)a


  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate
  end

  def changeset_delete(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate
  end

  def blocked_changeset(struct, blocked) when blocked in [true, false] do
    struct
    |> cast(%{blocked: blocked}, @fields)
    |> validate
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :user_id])
    |> validate_format(:name, ~r/^[a-z0-9\.\-_]+$/i)
    |> validate_length(:name, min: 2, max: 25)
  end

end
