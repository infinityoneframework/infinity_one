defmodule OneChat.Direct do
  use OneModel, schema: OneChat.Schema.Direct

  alias OneChat.Schema.Channel

  def migrate_db() do
    __MODULE__.list()
    |> Enum.reduce([], fn
      %{friend_id: nil} = direct, acc ->
        friend = InfinityOne.Accounts.get_by_username(direct.users)
        case __MODULE__.update(direct, %{friend_id: friend.id}) do
          {:ok, _} -> acc
          {:error, changeset} -> [changeset | acc]
        end
      _, acc -> acc
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

  def get_friend_channel_names(user_id) do
    @repo.all from d in @schema,
      join: c in Channel,
      on: d.channel_id == c.id,
      where: d.user_id == ^user_id,
      select: {c.name, c.id}
  end
end
