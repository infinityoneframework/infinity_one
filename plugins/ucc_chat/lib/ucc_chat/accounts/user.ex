defmodule UccChat.Accounts.User do
  use Unbrella.Plugin.Schema, UcxUcc.Accounts.User
  alias UcxUcc.Accounts.User
  import Ecto.Query

  Code.ensure_compiled(UccChat.Subscription)
  Code.ensure_compiled(UccChat.Channel)

  extend_schema UcxUcc.Accounts.User do

    field :status, :string, default: "offline", virtual: true
    field :subscription_hidden, :boolean, virtual: true

    belongs_to :open, UccChat.Channel, foreign_key: :open_id

    has_many :subscriptions, UccChat.Subscription, on_delete: :nilify_all
    has_many :channels, through: [:subscriptions, :channel], on_delete: :nilify_all
    has_many :messages, UccChat.Message, on_delete: :nilify_all
    has_many :stared_messages, UccChat.StaredMessage, on_delete: :nilify_all
    has_many :owns, UccChat.Channel, foreign_key: :user_id, on_delete: :nilify_all
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
