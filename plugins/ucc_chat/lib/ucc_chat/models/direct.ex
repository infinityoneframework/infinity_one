defmodule UccChat.Direct do
  use UccModel, schema: UccChat.Schema.Direct

  alias UccChat.Schema.Channel

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

  def get_friend_channel_names(user_id) do
    @repo.all from d in @schema,
      join: c in Channel,
      on: d.channel_id == c.id,
      where: d.user_id == ^user_id,
      select: {c.name, c.id}
  end
end
