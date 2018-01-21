defmodule UccChatWeb.UserChannel.SideNav.Channels do
  import Rebel.Core
  import Phoenix.View, only: [render_to_string: 3]
  import UcxUccWeb.Gettext

  alias UcxUccWeb.Query
  alias UccChat.{SideNavService, Channel, ChannelService}
  alias UccChatWeb.{SideNavView, RebelChannel.Client}
  alias UcxUcc.Accounts

  require Logger

  def channels_select(socket, sender, client \\ Client) do
    sender
    |> get_filter_options()
    |> render_channels(socket.assigns.user_id, socket)
  end

  def channels_search(socket, sender, client \\ Client) do
    match = exec_js!(socket, "$('#channel-search').val();")
    sender
    |> get_filter_options()
    |> Map.put(:search, "%" <> match <> "%")
    |> render_channels(socket.assigns.user_id, socket)
  end

  defp render_channels(options, user_id, socket) do
    user = Accounts.get_user user_id, preload: [:roles, user_roles: :role]
    channels = Channel.get_channels_search(user_id, options.search , options) # |> IO.inspect(label: "channels")
    html = Phoenix.View.render_to_string UccChatWeb.SideNavView,
      "list_combined_flex_list.html",  channels: channels, current_user: user
    Query.update(socket, :html, set: html, on: "ul.channel_list")
  end

  defp get_filter_options(%{"form" => form} = sender) do
    %{search: "%" <> form["channel-search"] <> "%"}
    |> channel_type_opt(form)
    |> show_opt(form)
    |> sort_opt(form)
  end

  defp channel_type_opt(opts, %{"channel-type" => "all"}),     do: Map.put(opts, :types, [0, 1])
  defp channel_type_opt(opts, %{"channel-type" => "private"}), do: Map.put(opts, :types, [1])
  defp channel_type_opt(opts, %{"channel-type" => "public"}),  do: Map.put(opts, :types, [0])
  defp channel_type_opt(opts, _), do: opts

  defp show_opt(opts, %{"show" => "all"}), do: opts
  defp show_opt(opts, %{"show" => "joined"}), do: Map.put(opts, :joined, true)
  defp show_opt(opts, _), do: opts

  defp sort_opt(opts, %{"sort-channels" => "name" }), do: Map.put(opts, :order_by, :name)
  defp sort_opt(opts, %{"sort-channels" => "msgs" }), do: Map.put(opts, :order_by, :msgs)
  defp sort_opt(opts, _), do: opts

  def create_channel(socket, sender) do
    Query.delete(socket, class: "animated-hidden", on: ".flex-nav.create-channel")
  end

  def create_channel_search_members(socket, %{"event" => %{"key" => key}} = sender)
    when key in ~w(Tab Enter) do

    socket
    |> exec_js!("$('li.-autocomplete-item.selected').attr('data-username');")
    |> select_member(socket)
  end

  def create_channel_search_members(socket, sender) do
    socket
    |> exec_js!("$('input#channel-members').val();")
    |> render_members_list(socket, sender)
  end

  defp render_members_list("", socket, _sender) do
    clear_selected_users(socket)
  end
  defp render_members_list(username, socket, sender) do
    user = Accounts.get_user(socket.assigns.user_id)
    exclude = get_selected_users(sender["form"])
    users =
      "%" <> username <> "%"
      |> Accounts.list_all_users_by_pattern({:username, exclude}, 1000)
      |> Enum.take(6)
      |> Enum.map(& struct(&1, status: UccChat.PresenceAgent.get(&1.id)))

    html = render_to_string SideNavView, "create_combined_flex_autocomplete_user.html",
      [user: user, users: users]
    socket
    |> Query.update(:replaceWith, set: html, on: ".-autocomplete-container")
    |> async_js("$('input#channel-members').focus();")
  end

  defp get_selected_users(form) do
    Enum.reduce(form, [], fn {key, _val}, acc ->
      case Regex.run(~r/^members\[(.+)\]$/, key) do
        [_, username] -> [username | acc]
        _ -> acc
      end
    end)
  end

  def create_channel_save(socket, sender) do
    current_user = Accounts.get_user(socket.assigns.user_id,
      preload: [:roles, user_roles: [:role]])

    form = sender["form"]
    type = if Rebel.Query.select(socket, prop: "checked", from: "input#channel-type"),
      do: 1, else: 0
    ro = Rebel.Query.select(socket, prop: "checked", from: "input#channel-read-only")
    name = form["channel[name]"]
    selected_users = get_selected_users(sender["form"])

    with nil <- Channel.get_by(name: name),
         {:ok, channel} <- ChannelService.insert_channel(current_user,
          %{name: name, type: type, read_only: ro, user_id: current_user.id}),
         {:ok, _} <- ChannelService.add_user_to_channel(channel, current_user.id) do

      socket
      |> Client.toastr(:success, ~g(Channel created sucessfully))
      |> close_create_channel()
      |> clear_selected_users()
      |> Query.insert(:class, set: "animated-hidden", on: ".flex-nav.create-channel")
      |> invite_members(selected_users, channel, current_user)
    else
      {:error, message} ->
        Client.toastr(socket, :error, format_error(message))
      {:error, _, changeset, _} ->
        Client.toastr(socket, :error, format_error(changeset))
      channel = %{} ->
        Client.toastr(socket, :error, ~g(That channel name already exists!))
      other ->
        Logger.error "other: " <> inspect(other)
        Client.toastr(socket, :error, ~g(Something went wrong!))
    end
  end

  defp invite_members(socket, selected_users, channel, current_user) do
    spawn fn ->
      # lets save some response time by doing this as a background task
      Enum.each(selected_users, fn username ->
        with %{} = user <- Accounts.get_by_username(username),
             {:ok, _} <- ChannelService.invite_user(user, channel.id, current_user.id) do
          Client.toastr(socket, :success, gettext("Added %{user} to the channel",
            user: user.username))
        else
          {:error, error} ->
            Logger.error inspect(error)
            Client.toastr(socket, :error,
              gettext("Problem adding %{user} to the channel.", user: username))
          nil ->
            Client.toastr(socket, :error,
              gettext("Problem adding %{user}. That user does not exist.", user: username))
          _ ->
            Client.toastr(socket, :error,
              gettext("Problem adding %{user} to the channel.", user: username))
        end
      end)
    end
    socket
  end

  def create_channel_cancel(socket, sender) do
    close_create_channel(socket)
  end

  defp close_create_channel(socket) do
    html = render_to_string(SideNavView, "create_combined_flex.html", [])
    socket
    |> Query.update(:html, set: html, on: ".flex-nav.create-channel section")
    |> Query.insert(:class, set: "animated-hidden", on: ".flex-nav.create-channel")
  end

  def format_error(%Ecto.Changeset{errors: errors}) do
    Enum.reduce(errors, [], fn {field, {error, _}}, message ->
      [to_string(field) <> ": " <> error | message]
    end)
    |> Enum.join(", \n")
  end
  def format_error(term), do: to_string(term)

  def create_channel_select_member(socket, sender) do
    select_member(sender["dataset"]["username"], socket)
  end

  defp select_member(nil, socket) do
    Client.toastr(socket, ~g(Something went wrong!))
    socket
  end

  defp select_member(username, socket) do
    html = render_to_string SideNavView, "create_combined_flex_selected_user.html",
      user: %{username: username}
    socket
    |> Rebel.Query.insert(html, append: "ul.selected-users")
    |> clear_selected_users
  end

  def create_channel_remove_member(socket, sender) do
    Query.delete(socket, closest: "li", on: this(sender))
  end

  defp clear_selected_users(socket) do
    socket
    |> Query.update(:value, set: "", on: "input.search#channel-members")
    |> Query.insert(:class, set: "animated-hidden", on: ".-autocomplete-container")
    |> Query.delete(".-autocomplete-list")
  end
end
