defmodule UccChat.Direct do
  use UccModel, schema: UccChat.Schema.Direct

  def migrate_db() do
    __MODULE__.list()
    |> Enum.reduce([], fn direct, acc ->
      user = UcxUcc.Accounts.get_by_username(direct.users)
      case __MODULE__.update(direct, %{friend_id: user.id}) do
        {:ok, _} -> acc
        {:error, changeset} -> [changeset | acc]
      end
    end)
  end
end
