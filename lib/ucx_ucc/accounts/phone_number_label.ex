defmodule UcxUcc.Accounts.PhoneNumberLabel do
  use Ecto.Schema
  import Ecto.Changeset
  alias UcxUcc.Accounts.{PhoneNumberLabel, PhoneNumber}


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phone_number_labels" do
    field :name, :string
    has_many :phone_number_id, PhoneNumber

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(%PhoneNumberLabel{} = phone_number_label, attrs) do
    phone_number_label
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
