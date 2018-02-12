defmodule UccWebrtc.Schema.ClientDevice do
  use UccWebrtc.Shared, :schema

  # @primary_key {:id, :binary_id, autogenerate: true}
  # @foreign_key_type :binary_id

  schema "client_devices" do
    field :ip_addr, :integer
    field :handsfree_input_id, :string
    field :handsfree_output_id, :string
    field :headset_input_id, :string
    field :headset_output_id, :string
    field :video_input_id, :string
    belongs_to :user, UcxUcc.Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @fields ~w(ip_addr user_id handsfree_input_id handsfree_output_id
    headset_input_id headset_output_id video_input_id)a

  def model, do: UccWebrtc.ClientDevice
  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required([:user_id, :ip_addr])
    |> unique_constraint(:user_id, name: :client_devices_index)
  end
end
