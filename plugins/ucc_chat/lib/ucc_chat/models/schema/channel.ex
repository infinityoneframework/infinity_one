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
    field :private, :boolean, virtual: true

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
    params = remove_on_booleans(params)
    struct
    |> cast(params, @fields)
    |> validate(params)
  end

  def changeset_delete(struct, params \\ %{}) do
    params = remove_on_booleans(params)
    struct
    |> cast(params, @fields)
    |> validate
  end

  def changeset_update(struct, params \\ %{}) do
    params = remove_on_booleans(params)
    struct
    |> cast(params, @fields)
    |> validate(params)
  end

  def blocked_changeset(struct, blocked) when blocked in [true, false] do
    struct
    |> cast(%{blocked: blocked}, @fields)
    |> validate
  end

  def validate(changeset, params \\ %{}) do
    params = remove_on_booleans(params)
    changeset
    |> validate_required([:name, :user_id])
    |> validate_format(:name, ~r/^[a-z0-9\.\-_]+$/i)
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

  defp remove_on_booleans(params) do
    Enum.reduce ~w(archived private read_only), params, fn field, params ->
      if params[field] == "on" do
        Map.delete params, field
      else
        params
      end
    end
  end
end
