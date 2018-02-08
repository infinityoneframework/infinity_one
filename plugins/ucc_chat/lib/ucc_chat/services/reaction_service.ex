defmodule UccChat.ReactionService do
  use UccChat.Shared, :service

  alias UccChat.{Message, MessageService, Reaction}
  alias UcxUcc.UccPubSub
  # alias UccChatWeb.Client

  require Logger

  def select("select", params, %{assigns: assigns}) do
    # Logger.warn "ReactionService.select message_id: " <> params["message_id"]
    user = Helpers.get_user assigns.user_id
    emoji = params["reaction"]

    message = Message.get params["message_id"],
      preload: MessageService.preloads()

    case Enum.find message.reactions, &(&1.emoji == emoji) do
      nil ->
        insert_reaction emoji, message.id, user.id
      reaction ->
        update_reaction reaction, user.id
    end
    message = Message.get params["message_id"],
      preload: MessageService.preloads()

    UccPubSub.broadcast "message:update:reactions", "channel:" <> message.channel_id,
      %{message: message}

    nil
  end

  def insert_reaction(emoji, message_id, user_id) do
    case Reaction.create(%{emoji: emoji, message_id: message_id,
      user_ids: user_id, count: 1}) do
      {:ok, _} ->
        nil
      {:error, _cs} ->
        {:error, %{error: ~g(Problem adding reaction)}}
    end
  end

  def update_reaction(reaction, user_id) do
    user_ids = reaction_user_ids reaction

    case Enum.any?(user_ids, &(&1 == user_id)) do
      true ->
        remove_user_reaction(reaction, user_id, user_ids)
      false ->
        add_user_reaction(reaction, user_id, user_ids)
    end
  end

  defp remove_user_reaction(%{count: count} = reaction, user_id, user_ids) do
    user_ids =
      user_ids
      |> Enum.reject(&(&1 == user_id))
      |> Enum.join(" ")

    if user_ids == "" do
      Repo.delete reaction
    else
      Reaction.update(reaction, %{count: count - 1, user_ids: user_ids})
    end
  end

  defp add_user_reaction(%{count: count} = reaction, user_id, user_ids) do
    user_ids =
      (user_ids ++ [user_id])
      |> Enum.join(" ")

    Reaction.update(reaction, %{count: count + 1, user_ids: user_ids})
  end

  defp reaction_user_ids(reaction) do
    String.split(reaction.user_ids, " ", trim: true)
  end

  def get_reaction_people_names(reaction, user) do
    username = user.username
    {you, rest} =
      reaction
      |> reaction_user_ids
      |> Enum.map(&Helpers.get_user(&1, preload: []))
      |> Enum.reject(&(is_nil &1))
      |> Enum.reduce({[], []}, fn user, {you, acc} ->
        case user.username do
          ^username -> {[~g"you"], acc}
          username -> {you, ["@" <> username | acc]}
        end
      end)

    case you ++ Enum.sort(rest) do
      [one] -> one
      [first | rest] ->
        Enum.join(rest, ", ") <> " " <> ~g(and) <> " " <> first
    end
  end
end
