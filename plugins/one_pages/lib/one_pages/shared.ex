defmodule OnePages.Shared do

  def schema do
    quote do
      use Ecto.Schema
      # use OnePagesWeb.Gettext

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      # alias OneChat.Settings

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  @doc """
  When used, dispatch to the appropriate service/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
