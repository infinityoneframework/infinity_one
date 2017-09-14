defmodule UccChatWeb.RoomChannel.EmojiInput do
  use UccLogger
  use UcxUccWeb.Gettext

  import UccChatWeb.RebelChannel.Client

  alias UccChatWeb.RoomChannel.EmojiInput.Client
  alias UccChat.{Emoji, EmojiService, AccountService}
  alias UccChatWeb.EmojiView
  alias UcxUcc.Accounts

  use UccChatWeb.RoomChannel.Constants

  def emoji_show(socket, sender, client \\ Client) do
    client.send_js socket, "chat_emoji.toggle_picker();"
    socket
  end

  def emoji_filter(socket, sender, client \\ Client) do
    Logger.info "filter sender: #{inspect sender}"
    name = sender["dataset"]["name"]
    id = sender["rebel_id"]
    client.send_js socket, """
      document.querySelector('.filter-item.active').classList.remove('active');
      document.querySelector('.emoji-list.visible').classList.remove('visible');
      document.querySelector('[rebel-id="#{id}"]').classList.add('active');
      document.querySelector('.emoji-list.#{name}').classList.add('visible');
      document.querySelector('.emoji-filter input.search').value = '';
      Rebel.set_event_handlers('.emoji-picker');
      """
    EmojiService.set_emoji_category socket.assigns.user_id, name
    socket
  end

  def emoji_select(socket, sender, client \\ Client) do
    Logger.info "select sender: #{inspect sender}"
    start = sender["caret"]["start"]
    content = sender["content"]
    emoji =
      case Regex.run ~r/title="([^"]+)"/, sender["html"] do
        [_, emoji] -> emoji
        _ -> ""
      end
    {head, tail} = String.split_at content, start
    content = Poison.encode! head <> emoji <> tail
    client.send_js socket, """
      var te = document.querySelector('#{@message_box}');
      te.value = #{content};
      chat_emoji.close_picker();
      te.focus();
      """
    update_recent socket, String.replace(emoji, ":", ""), client
  end

  def update_recent(socket, emoji, client \\ Client) do
    case EmojiService.update_emoji_recent(socket.assigns.user_id, emoji) do
      {:ok, account} ->
        account
        |> AccountService.emoji_recents
        |> update_emoji_list(account, ".emojis ul.recent", socket, client)
      {:error, _} ->
        toastr! socket, :error, ~g(Problem updating emoji recent)
      nil -> :ok
    end
    socket
  end

  def emoji_tone_open(socket, sender, client \\ Client) do
    Logger.info "tone open sender: #{inspect sender}"
    client.send_js socket, "document.querySelector('ul.tone-selector').classList.toggle('show')"
    socket
  end

  def emoji_tone_select(socket, sender, client \\ Client) do
    Logger.info "tone select sender: #{inspect sender}"
    tone = sender["dataset"]["tone"]
    EmojiService.set_emoji_tone(socket.assigns.user_id, tone)

    tone_list =
      tone
      |> Emoji.tone_list
      |> Poison.encode!
      |> IO.inspect(label: "tone list")

    client.send_js socket, """
      var tl = #{tone_list};
      var keys = Object.keys(tl);
      for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        document.querySelector('li.emoji-' + key).innerHTML = tl[key];
      };
      document.querySelector('ul.tone-selector').classList.remove('show');
      document.querySelector('span.current-tone').className = 'current-tone tone-' + '#{tone}';
      """
    socket
  end

  def emoji_search(socket, sender, client \\ Client) do
    Logger.info "emoji_search sender: #{inspect sender}"
    user = Accounts.get_user socket.assigns.user_id, preload: [:account]
    category = Rebel.Core.exec_js! socket,
      "document.querySelector('.filter-item.active').getAttribute('data-name')"

IO.inspect category, label: "cat"
    sender["value"]
    |> String.replace(":", "")
    |> IO.inspect(label: "value")
    |> Emoji.search(category)
    |> IO.inspect(label: "search")
    |> update_emoji_list(user.account, ".emojis ul." <> category, socket, client)
  end

  defp update_emoji_list(emojis, account, selector, socket, client \\ Client) do
    IO.inspect emojis, label: "emojis"
    html =
      EmojiView
      |> Phoenix.View.render_to_string("emoji_category.html",
        emojis: emojis,
        tone_list: Emoji.tone_list(),
        tone: EmojiView.tone_append(account.emoji_tone))
      |> Poison.encode!

    client.send_js socket, """
      document.querySelector('#{selector}').innerHTML = #{html};
      Rebel.set_event_handlers('.emoji-picker');
      """
    socket
  end

end
