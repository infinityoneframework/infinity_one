defmodule UccChat.Accounts.User do
  use Unbrella.Plugin.Schema, UcxUcc.Accounts.User

  alias UccChat.Schema.{Subscription, Channel, StaredMessage}

  Code.ensure_compiled(Subscription)
  Code.ensure_compiled(Channel)

  extend_schema UcxUcc.Accounts.User do

    field :status, :string, default: "offline", virtual: true
    field :subscription_hidden, :boolean, virtual: true

    belongs_to :open, Channel, foreign_key: :open_id

    has_many :subscriptions, Subscription, on_delete: :nilify_all
    has_many :channels, through: [:subscriptions, :channel], on_delete: :nilify_all
    has_many :messages, Message, on_delete: :nilify_all
    has_many :stared_messages, StaredMessage, on_delete: :nilify_all
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
  end
end
