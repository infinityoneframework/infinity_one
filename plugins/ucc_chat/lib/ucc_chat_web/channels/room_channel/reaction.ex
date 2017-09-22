defmodule UccChatWeb.RoomChannel.Reaction do
  use UccLogger
  use UcxUccWeb.Gettext
  use UccChatWeb.RoomChannel.Constants

  # import UccChatWeb.RebelChannel.Client

  alias UccChatWeb.Client
  alias UccChat.{Reaction, Message, MessageService}
  alias UcxUcc.{Accounts, Repo}


  def select(socket, sender, client \\ Client) do
    # Logger.info "sender: #{inspect sender}"
    emoji = ":" <> sender["dataset"]["emoji"] <> ":"
    user = Accounts.get_user socket.assigns.user_id
    message_id = Rebel.get_assigns socket, :reaction
    Rebel.put_assigns socket, :reaction, nil
    # IO.inspect {message_id, emoji}

    message = Message.get message_id,
      preload: MessageService.preloads()

    case Enum.find message.reactions, &(&1.emoji == emoji) do
      nil ->
        insert_reaction socket, emoji, message.id, user.id, client
      reaction ->
        update_reaction reaction, user.id
    end
    MessageService.broadcast_updated_message message, reaction: true
    client.send_js socket, """
      chat_emoji.close_picker();
      document.querySelector('#{@message_box}').focus();
      """
    emoji
  end

  def insert_reaction(socket, emoji, message_id, user_id, client \\ Client) do
    case Reaction.create(%{emoji: emoji, message_id: message_id,
      user_ids: user_id, count: 1}) do
      {:ok, _} ->
        nil
      {:error, _cs} ->
        client.toastr! socket, :error, ~g(Problem adding reaction)
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
      # TODO: change this to reaction.delete
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
    reaction
    |> reaction_user_ids
    |> Enum.map(&Accounts.get_user/1)
    |> Enum.reject(&(is_nil &1))
    |> Enum.map(fn user ->
      case user.username do
        ^username -> "you"
        username -> "@" <> username
      end
    end)
    |> case do
      [one] -> one
      [first | rest] ->
        Enum.join(rest, ", ") <> " and " <> first
    end
  end

end
