defmodule UccWebrtc.Shared do

  # def service do
  #   quote do
  #     import Ecto.Query
  #     alias UcxUcc.Repo
  #     alias UcxUcc.Accounts.{User, UserRole}
  #     alias UccChat.{Web.RoomChannel, Web.UserChannel}
  #     alias UccChat.ServiceHelpers, as: Helpers
  #     require UccChatWeb.SharedView
  #     use UcxUccWeb.Gettext
  #     import Phoenix.HTML, only: [safe_to_string: 1]
  #   end
  # end

  def schema do
    quote do
      use Ecto.Schema
      use UcxUccWeb.Gettext

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      # alias UccChat.Settings

      # @primary_key {:id, :binary_id, autogenerate: true}
      # @foreign_key_type :binary_id
    end
  end

  @doc """
  When used, dispatch to the appropriate service/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
