defmodule InfinityOne.Accounts.UserRole do
  @moduledoc """
  The join table between users and roles.

  Handles the many to many association between `InfinityOne.Accounts.User`
  and `InfinityOne.Accounts.Role`.

  Also contains a scope field which can contain the following vales:

  * nil - indicates the global scope.
  * channel_id - for rooms scoped roles

  ## OnePubSub notifications

  Broadcasts the following `InfinityOne.OnePubSub` events for a user:

  * "role:insert", "channel:" <> channel_id - when a new scoped role is added
  * "role:insert", "channel:global" - when a new global role is added
  * "role:delete", "channel:" <> channel_id - when a scoped role is removed
  * "role:delete", "channel:global" - when a global role is removed

  The broadcast is handled in a `Ecto.Changeset.prepare_changes/1`.
  """
  use Ecto.Schema
  import Ecto.{Query, Changeset}, warn: false

  alias InfinityOne.{OnePubSub, Accounts}

  schema "users_roles" do
    field :scope, :binary_id, default: nil  # id of room
    belongs_to :user, InfinityOne.Accounts.User, type: :binary_id
    belongs_to :role, InfinityOne.Accounts.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:scope, :user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> prepare_changes(&prepare_notify/1)
  end

  defp prepare_notify(%{action: :insert} = changeset) do
    role = Accounts.get_role! changeset.changes.role_id

    if OneSettings.display_roles() && notify_role?(role.name) do
      user = Accounts.get_user changeset.changes.user_id
      scope = changeset.changes[:scope] || "global"

      OnePubSub.broadcast "role:insert", "channel:" <> scope, %{
        username: user.username,
        role: String.capitalize(role.name)
      }
    end
    changeset
  end

  defp prepare_notify(%{action: :delete} = changeset) do
    role = Accounts.get_role! changeset.data.role_id

    if OneSettings.display_roles() and notify_role?(role.name) do
      user = Accounts.get_user changeset.data.user_id
      scope = changeset.data.scope || "global"

      OnePubSub.broadcast "role:delete", "channel:" <> scope, %{
        username: user.username,
        role: String.capitalize(role.name)
      }
    end
    changeset
  end

  defp prepare_notify(changeset) do
    changeset
  end

  defp notify_role?("user"), do: false
  defp notify_role?(_), do: true
end
