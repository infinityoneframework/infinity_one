defmodule OneChat.Schema.Channel do
  use OneChat.Shared, :schema

  alias OneChat.Schema.{
    Message, Subscription, Attachment, StarredMessage, Notification
  }
  alias InfinityOne.Accounts.User

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
    field :private, :boolean, virtual: true
    field :nway, :boolean, default: false

    has_many :subscriptions, Subscription, on_delete: :delete_all
    has_many :users, through: [:subscriptions, :user], on_delete: :nilify_all
    has_many :starred_messages, StarredMessage, on_delete: :delete_all
    has_many :messages, Message, on_delete: :delete_all
    has_many :notifications, Notification, on_delete: :delete_all
    has_many :attachments, Attachment, on_delete: :delete_all

    belongs_to :owner, User, foreign_key: :user_id

    timestamps(type: :utc_datetime)
  end

  @fields ~w(archived name type topic read_only blocked default user_id description active nway)a

  def model, do: OneChat.Channel

  def validate_name_re, do: ~r/^[a-z0-9\.\-_]+$/i
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> unique_constraint(:name)
    |> validate(params)
  end

  def changeset_delete(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> unique_constraint(:name)
    |> validate(params)
  end

  def blocked_changeset(struct, blocked) when blocked in [true, false] do
    struct
    |> cast(%{blocked: blocked}, @fields)
    |> validate
  end

  def validate(changeset, params \\ %{}) do
    changeset
    |> validate_required([:name, :user_id])
    |> validate_format(:name, validate_name_re())
    |> validate_length(:name, min: 2, max: 55)
    |> handle_virtual_private(params)
  end

  def handle_virtual_private(changeset, %{"private" => private}) do
    put_change changeset, :type, translate_private(private)
  end
  def handle_virtual_private(changeset, _) do
    changeset
  end

  defp translate_private(true), do: 1
  defp translate_private("true"), do: 1
  defp translate_private(_), do: 0

end
