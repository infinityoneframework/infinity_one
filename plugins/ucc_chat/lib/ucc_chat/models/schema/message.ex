defmodule UccChat.Schema.Message do
  use UccChat.Shared, :schema

  import Ecto.Changeset

  alias UcxUcc.Accounts.User
  alias UccChat.Schema.{Channel, Reaction, Attachment, StarredMessage}

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

  @fields [:body, :user_id, :channel_id, :sequential, :timestamp, :edited_id, :type, :expire_at, :system]
  @required [:user_id]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@required)
    |> add_timestamp
  end

  def add_timestamp(%{data: %{timestamp: nil}} = changeset) do
    put_change(changeset, :timestamp, UccChat.ServiceHelpers.get_timestamp())
  end
  def add_timestamp(changeset) do
    changeset
  end

end
