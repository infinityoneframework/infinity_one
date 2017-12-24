defmodule UccChat.Accounts.User do
  use Unbrella.Plugin.Schema, UcxUcc.Accounts.User

  alias UccChat.Schema.{Message, Subscription, Channel, StarredMessage}

  Code.ensure_compiled(Subscription)
  Code.ensure_compiled(Channel)
  Code.ensure_compiled(Message)

  extend_schema UcxUcc.Accounts.User do
    field :status, :string, default: "offline", virtual: true
    field :subscription_hidden, :boolean, virtual: true

    field :chat_status, :string, default: ""
    belongs_to :open, Channel, foreign_key: :open_id

    has_many :subscriptions, Subscription, on_delete: :nilify_all
    # has_many :channels, through: [:subscriptions, :channel], on_delete: :nilify_all
    many_to_many :channels, Channel, join_through: Subscription
    has_many :messages, Message, on_delete: :nilify_all
    has_many :starred_messages, StarredMessage, on_delete: :nilify_all
    has_many :owns, Channel, foreign_key: :user_id, on_delete: :nilify_all
  end

  @fields [:chat_status, :status, :subscription_hidden, :open_id]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(changeset, params \\ %{}) do
    changeset
    |> cast(params, @fields)
    |> validate_required([])
    |> cast_assoc(:subscriptions)
  end
end
