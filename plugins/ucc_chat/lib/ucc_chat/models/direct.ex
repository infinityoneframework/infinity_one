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

  def get(user_id, friend_id, channel_id, opts \\ []) do
    preload = opts[:preload] || []
    get_by user_id: user_id, friend_id: friend_id, channel_id: channel_id, preload: preload
  end

  def get_friend(user_id, channel_id, opts \\ []) do
    preload = opts[:preload] || []
    get_by user_id: user_id, channel_id: channel_id, preload: preload
  end
end
