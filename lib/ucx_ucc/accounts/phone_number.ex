defmodule UcxUcc.Accounts.PhoneNumber do
  # use Ecto.Schema
  use Unbrella.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.{PhoneNumber, User, PhoneNumberLabel}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phone_numbers" do
    field :number, :string
    field :primary, :boolean, default: false
    field :type, :string
    belongs_to :user, User
    belongs_to :label, PhoneNumberLabel

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(%PhoneNumber{} = phone_number, attrs) do
    phone_number
    |> cast(attrs, [:number, :primary, :type, :label_id, :user_id])
    |> validate_required([:number, :primary, :label_id, :user_id])
    |> foreign_key_constraint(:label_id, name: :phone_numbers_label_id_fkey)
    |> validate_format(:number, ~r/^[0-9\+\-\(\)\. ]+$/)
    |> plugin_changesets(attrs, __MODULE__)
  end
end
