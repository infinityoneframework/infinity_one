defmodule UccSettings.Settings.Config do
  use Ecto.Schema
  import Ecto.Changeset

  alias UccSettings.Settings.Config 

  schema "settings_configs" do
    field :default, :string
    field :name, :string
    field :scope, :string
    field :type, :string
    field :value, :string

    timestamps()
  end

  def changeset(%Config{} = config, attrs) do
    config
    |> cast(attrs, [:name, :scope, :type, :value, :default])
    |> validate_required([:name, :scope, :type])
  end
end
