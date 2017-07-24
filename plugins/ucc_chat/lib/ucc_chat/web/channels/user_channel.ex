defmodule UccChat.Web.UserChannel do
  use UccLogger
  use UccChat.Web, :channel
  use UcxUcc
  # use Rebel.Channel, name: "user", controllers: [
  #   UccChat.Web.ChannelController,
  # ]
  alias UcxUcc.UccPubSub

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import Rebel.Browser, warn: false
  # alias UccChat.Presence

  import Ecto.Query

  alias Phoenix.Socket.Broadcast
  alias UcxUcc.Repo
  alias UcxUcc.Accounts.{Account, User}
  alias UccChat.{
    Subscription, ChannelService, Channel,
    SideNavService, Web.AccountView, Web.UserSocket, Web.MasterView,
    Web.SharedView, ChannelService, SubscriptionService, InvitationService,
    UserService, EmojiService, Settings, FlexBarService, MessageService
  }
  alias UccAdmin.AdminService
  alias UcxUcc.Web.Endpoint
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.Schema.Subscription, as: SubscriptionSchema

  require UccChat.ChatConstants, as: CC

  def join_room(user_id, room) do
    # Logger.debug ("...join_room user_id: #{inspect user_id}")
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "room:join",
      %{room: room, user_id: user_id})
  end

  def leave_room(user_id, room) do
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "room:leave",
      %{room: room, user_id: user_id})
  end

  def notify_mention(%{user_id: user_id, channel_id: channel_id}, body) do
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "room:mention",
      %{channel_id: channel_id, user_id: user_id, body: body})
  end
  def user_state(user_id, state) do
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "user:state",
      %{state: state})
  end

  intercept [
    "room:join",
    "room:leave",
    "room:mention",
    "user:state",
    "direct:new",
    "get:subscribed"
  ]

  def join(CC.chan_user() <>  user_id = event, params, socket) do
    trace(CC.chan_user() <> user_id, params)
    send(self(), {:after_join, params})
    {:ok, socket}
  end

  ###############
  # Outgoing Incoming Messages

  def handle_out("get:subscribed" = ev, msg, socket) do
    trace ev, msg
    Kernel.send msg.pid, {:subscribed, socket.assigns[:subscribed]}
    {:noreply, socket}
  end

  def handle_out("room:join", msg, socket) do
    trace "room:join", msg
    %{room: room} = msg
    user_id = socket.assigns.user_id
    UserSocket.push_message_box(socket, socket.assigns.channel_id, user_id)
    update_rooms_list(socket)
    clear_unreads(room, socket)
    {:noreply, subscribe([room], socket)}
  end

  def handle_out("room:leave" = ev, msg, socket) do
    %{room: room} = msg
    trace ev, msg, "assigns: #{inspect socket.assigns}"
    # UserSocket.push_message_box(socket, socket.assigns.channel_id, socket.assigns.user_id)
    socket.endpoint.unsubscribe(CC.chan_room <> room)
    update_rooms_list(socket)
    {:noreply, assign(socket, :subscribed,
      List.delete(socket.assigns[:subscribed], room))}
  end
  def handle_out("room:mention", msg, socket) do
    push_room_mention(msg, socket)
    {:noreply, socket}
  end
  def handle_out("user:state", msg, socket) do
    {:noreply, handle_user_state(msg, socket)}
  end
  def handle_out("direct:new", msg, socket) do
    %{room: room} = msg
    update_rooms_list(socket)
    {:noreply, subscribe([room], socket)}
  end

  def handle_user_state(%{state: "idle"}, socket) do
    trace "idle", ""
    push socket, "focus:change", %{state: false, msg: "idle"}
    assign socket, :user_state, "idle"
  end
  def handle_user_state(%{state: "active"}, socket) do
    trace "active", ""
    push socket, "focus:change", %{state: true, msg: "active"}
    clear_unreads(socket)
    assign socket, :user_state, "active"
  end

  def push_room_mention(msg, socket) do
    # %{channel_id: channel_id} = msg
    Process.send_after self(),
      {:update_mention, msg, socket.assigns.user_id}, 250
    socket
  end

  def push_update_direct_message(msg, socket) do
    Process.send_after self(),
      {:update_direct_message, msg, socket.assigns.user_id}, 250
    socket
  end

  ###############
  # Incoming Messages

  def handle_in(ev = "reaction:" <> action, params, socket) do
    trace ev, params
    case UccChat.ReactionService.select(action, params, socket) do
      nil -> {:noreply, socket}
      res -> {:reply, res, socket}
    end
  end

  def handle_in("emoji:" <> emoji, params, socket) do
    EmojiService.handle_in(emoji, params, socket)
  end

  def handle_in("subscribe" = ev, params, socket) do
    trace ev, params, "assigns: #{inspect socket.assigns}"
    {:noreply, socket}
  end

  def handle_in("side_nav:open" = ev, %{"page" => "account"} = params,
    socket) do
    trace ev, params

    user = Helpers.get_user!(socket)
    account_cs = Account.changeset(user.account, %{})
    html = Helpers.render(AccountView, "account_preferences.html",
      user: user, account_changeset: account_cs)
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}

    html = Helpers.render(AccountView, "account_flex.html")
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("side_nav:open" = ev, %{"page" => "admin"} = params, socket) do
    trace ev, params

    user = Helpers.get_user!(socket)

    html = AdminService.render_info(user)
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}

    html = Helpers.render(UccAdmin.Web.AdminView, "admin_flex.html",
      user: user)
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("side_nav:more_channels" = ev, params, socket) do
    trace ev, params

    html = SideNavService.render_more_channels(socket.assigns.user_id)
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("side_nav:more_users" = ev, params, socket) do
    trace ev, params

    html = SideNavService.render_more_users(socket.assigns.user_id)
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("side_nav:close" = ev, params, socket) do
    trace ev, params

    {:noreply, socket}
  end

  def handle_in("account:preferences:save" = ev, params, socket) do
    trace ev, params, "assigns: #{inspect socket.assigns}"
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("account")
    resp =
      socket
      |> Helpers.get_user!
      |> Map.get(:account)
      |> Account.changeset(params)
      |> Repo.update
      |> case do
        {:ok, _account} ->
          {:ok, %{success: ~g"Account updated successfully"}}
        {:error, _cs} ->
          {:ok, %{error: ~g"There a problem updating your account."}}
      end
    {:reply, resp, socket}
  end

  def handle_in("account:profile:save" = ev, params, socket) do
    trace ev, params, "assigns: #{inspect socket.assigns}"
    params =
      params
      |> Helpers.normalize_form_params
      |> Map.get("user")
    resp =
      socket
      |> Helpers.get_user!
      |> User.changeset(params)
      |> Repo.update
      |> case do
        {:ok, _account} ->
          {:ok, %{success: ~g"Profile updated successfully"}}
        {:error, cs} ->
          Logger.error "cs.errors: #{inspect cs.errors}"
          {:ok, %{error: ~g"There a problem updating your profile."}}
      end
    {:reply, resp, socket}
  end

  @links ~w(preferences profile)
  def handle_in(ev = "account_link:click:" <> link, params, socket)
    when link in @links do

    trace ev, params
    user = Helpers.get_user(socket.assigns.user_id)
    user_cs = User.changeset(user, %{})
    account_cs = Account.changeset(user.account, %{})
    html = Helpers.render(AccountView, "account_#{link}.html", user: user,
      account_changeset: account_cs, user_changeset: user_cs)
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}
    {:noreply, socket}
  end

  def handle_in(ev = "mode:set:" <> mode, params, socket) do
    trace ev, params
    mode = if mode == "im", do: true, else: false
    user = Helpers.get_user!(socket)

    resp =
      user
      |> Map.get(:account)
      |> Account.changeset(%{chat_mode: mode})
      |> Repo.update
      |> case do
        {:ok, _} ->
          push socket, "window:reload", %{mode: mode}
          {:ok, %{}}
        {:error, _} ->
          {:error, %{error: ~g"There was a problem switching modes"}}
      end
    {:reply, resp, socket}
  end

  @links ~w(info general chat_general message permissions layout users rooms file_upload)
  def handle_in(ev = "admin_link:click:" <> link, params, socket) when link in @links do
    trace ev, params
    user = Helpers.get_user! socket
    html = AdminService.render user, link, "#{link}.html"
    push socket, "code:update", %{html: html, selector: ".main-content", action: "html"}
    {:noreply, socket}
  end

  def handle_in(ev = "admin_link:click:webrtc" , params, socket) do
    link = "webrtc"
    trace ev, params
    user = Helpers.get_user! socket
    html = AdminService.render user, link, "#{link}.html"
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}
    {:noreply, socket}
  end

  def handle_in(ev = "admin:" <> link, params, socket) do
    trace ev, params
    AdminService.handle_in(link, params, socket)
  end

  # def handle_in(ev = "flex:member-list:" <> action, params, socket) do
  #   debug ev, params
  #   FlexBarService.handle_in action, params, socket
  # end

  def handle_in(ev = "update:currentMessage", params, socket) do
    trace ev, params

    value = params["value"] || "0"
    assigns = socket.assigns
    last_read = SubscriptionService.get(assigns.channel_id, assigns.user_id,
      :last_read) || ""
    cond do
      last_read == "" or String.to_integer(last_read) < String.to_integer(value) ->
        SubscriptionService.update(assigns.channel_id, assigns.user_id,
          %{last_read: value})
      true ->
        nil
    end
    SubscriptionService.update(assigns.channel_id, assigns.user_id,
      %{current_message: value})
    {:noreply, socket}
  end
  def handle_in(ev = "get:currentMessage", params,
    %{assigns: assigns} = socket) do
    trace ev, params
    channel = Channel.get_by name: params["room"]
    if channel do
      res =
        case SubscriptionService.get channel.id, assigns.user_id,
          :current_message do
          :error -> {:error, %{}}
          value -> {:ok, %{value: value}}
        end
      {:reply, res, socket}
    else
      {:noreply, socket}
    end
  end
  def handle_in(ev = "last_read", params, %{assigns: assigns} = socket) do
    trace ev, params
    SubscriptionService.update assigns, %{last_read: params["last_read"]}
    {:noreply, socket}
  end
  def handle_in("invitation:resend", %{"email" => _email, "id" => id},
    socket) do
    case InvitationService.resend(id) do
      {:ok, message} ->
        {:reply, {:ok, %{success: message}}, socket}
      {:error, error} ->
        {:reply, {:error, %{error: error}}, socket}
    end
  end

  # default unknown handler
  def handle_in(event, params, socket) do
    Logger.warn "UserChannel.handle_in unknown event: #{inspect event}, " <>
      "params: #{inspect params}"
    {:noreply, socket}
  end

  ###############
  # Info messages

  def handle_info({:after_join, params}, socket) do
    trace "after_join", socket.assigns, inspect(params)
    user_id = socket.assigns.user_id

    new_assigns =
      params
      |> Enum.map(fn {k,v} ->
        {String.to_atom(k), v}
      end)
      |> Enum.into(%{})

    socket =
      socket
      |> struct(assigns: Map.merge(new_assigns, socket.assigns))
      |> assign(:subscribed, socket.assigns[:subscribed] || [])
      |> assign(:user_state, "active")

    socket =
      Repo.all(from s in SubscriptionSchema, where: s.user_id == ^user_id,
        preload: [:channel, {:user, :roles}])
      |> Enum.map(&(&1.channel.name))
      |> subscribe(socket)

    {:noreply, socket}
  end

  def handle_info(%Broadcast{topic: _, event: "get:subscribed",
    payload: payload}, socket) do

    trace "get:subscribed", payload

    send payload["pid"], {:subscribed, socket.assigns[:subscribed]}
    {:noreply, socket}
  end

  def handle_info(%Broadcast{topic: _, event: "room:update:name" = event,
    payload: payload}, socket) do
    trace event, payload
    push socket, event, payload
    # socket.endpoint.unsubscribe(CC.chan_room <> payload[:old_name])
    {:noreply, assign(socket, :subscribed,
      [payload[:new_name] | List.delete(socket.assigns[:subscribed],
      payload[:old_name])])}
  end
  def handle_info(%Broadcast{topic: _, event: "room:update:list" = event,
    payload: payload}, socket) do
    trace event, payload
    {:noreply, update_rooms_list(socket)}
  end
  def handle_info(%Broadcast{topic: "room:" <> room,
    event: "message:new" = event, payload: payload}, socket) do
    trace event, ""  #socket.assigns
    assigns = socket.assigns

    if room in assigns.subscribed do
      channel = Channel.get_by(name: room)
      Logger.warn "in the room ... #{assigns.user_id}, room: #{inspect room}"
      # unless channel.id == assigns.channel_id and assigns.user_state != "idle" do
      if channel.id != assigns.channel_id or assigns.user_state == "idle" do
        if channel.type == 2 do
          # Logger.warn "private channel ..."
          msg =
            if payload[:body] do
              %{body: payload[:body], username: assigns.username}
            else
              nil
            end
          push_update_direct_message(%{channel_id: channel.id, msg: msg},
            socket)
        end
        update_has_unread(channel, socket)
      end
    end
    {:noreply, socket}
  end

  def handle_info(%Broadcast{topic: _, event: "user:action" = event,
    payload: %{action: "unhide"} = payload}, %{assigns: assigns} = socket) do
    trace event, payload, "assigns: #{inspect assigns}"

    UserSocket.push_rooms_list_update(socket, payload.channel_id,
      payload.user_id)

    {:noreply, socket}
  end
  def handle_info(%Broadcast{topic: _, event: "user:entered" = event,
    payload: %{user: user} = payload},
    %{assigns: %{user: user} = assigns} = socket) do

    trace event, payload, "assigns: #{inspect assigns}"
    # old_channel_id = assigns[:channel_id]
    channel_id = payload[:channel_id]
    socket = %{assigns: _assigns} = assign(socket, :channel_id, channel_id)

    UccPubSub.broadcast "user:" <> assigns.user_id, "room:join",
      %{channel_id: channel_id}

    {:noreply, socket}
  end

  def handle_info(%Broadcast{topic: _, event: "room:delete" = event,
    payload: payload}, socket) do
    trace event, payload
    room = payload.room
    if Enum.any?(socket.assigns[:subscribed], &(&1 == room)) do
      update_rooms_list(socket)
      {:noreply, assign(socket, :subscribed,
        List.delete(socket.assigns[:subscribed], room))}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:update_mention, payload, user_id} = ev, socket) do
    trace "upate_mention", ev
    if UserService.open_channel_count(socket.assigns.user_id) > 1 do
      opens = UserService.open_channels(socket.assigns.user_id)
      Logger.error "found more than one open, room: " <>
        "#{inspect socket.assigns.room}, opens: #{inspect opens}"
    end
    %{channel_id: channel_id, body: body} = payload
    channel = Channel.get!(channel_id)
    with [sub] <- Repo.all(Subscription.get_by(channel_id: channel_id,
                    user_id: user_id)),
         open  <- Map.get(sub, :open),
         false <- socket.assigns.user_state == "active" and open,
         count <- ChannelService.get_unread(channel_id, user_id) do
      push(socket, "room:mention", %{room: channel.name, unread: count})

      if body do
        body = Helpers.strip_tags body
        user = Helpers.get_user user_id
        handle_notifications socket, user, channel, %{body: body,
          username: socket.assigns.username}
      end
    end
    {:noreply, socket}
  end

  def handle_info({:update_direct_message, payload, user_id} = ev, socket) do
    trace "upate_direct_message", ev, socket.assigns.user_state
    if UserService.open_channel_count(socket.assigns.user_id) > 1 do
      opens = UserService.open_channels(socket.assigns.user_id)
      Logger.error "found more than one open, room: " <>
        "#{inspect socket.assigns.room}, opens: #{inspect opens}"
    end
    %{channel_id: channel_id, msg: msg} = payload
    channel = Channel.get!(channel_id)
    with [sub] <- Repo.all(Subscription.get(channel_id, user_id)),
         # _ <- Logger.warn("update_direct_message unread: #{sub.unread}"),
         open  <- Map.get(sub, :open),
         # _ <- Logger.warn("open: #{inspect open}"),
         false <- socket.assigns.user_state == "active" and open,
         count <- ChannelService.get_unread(channel_id, user_id) do
      push(socket, "room:mention", %{room: channel.name, unread: count})
      if msg do
        user = Helpers.get_user(user_id)
        handle_notifications socket, user, channel,
          update_in(msg, [:body], &Helpers.strip_tags/1)
      end
    end
    {:noreply, socket}
  end

  # Default case to ignore messages we are not interested in
  def handle_info(%Broadcast{}, socket) do
    {:noreply, socket}
  end

  ###############
  # Helpers

  defp handle_notifications(socket, user, channel, payload) do
    payload = case UccChat.Settings.get_new_message_sound(user, channel.id) do
      nil -> payload
      sound -> Map.put(payload, :sound, sound)
    end
    if UccSettings.enable_desktop_notifications() do
      # Logger.warn "doing desktop notification"
      push socket, "notification:new", Map.put(payload, :duration,
        Settings.get_desktop_notification_duration(user, channel))
    else
      # Logger.warn "doing badges only notification"
      push socket, "notification:new", Map.put(payload, :badges_only, true)
    end
  end

  defp subscribe(channels, socket) do
    # trace inspect(channels), ""
    Enum.reduce channels, socket, fn channel, acc ->
      subscribed = acc.assigns[:subscribed]
      if channel in subscribed do
        acc
      else
        socket.endpoint.subscribe(CC.chan_room <> channel)
        assign(acc, :subscribed, [channel | subscribed])
      end
    end
  end

  defp update_rooms_list(%{assigns: assigns} = socket) do
    trace "", inspect(assigns)
    html = SideNavService.render_rooms_list(assigns[:channel_id],
      assigns[:user_id])
    push socket, "update:rooms", %{html: html}
    socket
  end

  defp clear_unreads(%{assigns: %{channel_id: channel_id}} = socket) do
    Logger.warn "clear_unreads/1: channel_id: #{inspect channel_id}, " <>
      "socket.assigns.user_id: #{inspect socket.assigns.user_id}"
    channel_id
    |> Channel.get
    |> Map.get(:name)
    |> clear_unreads(socket)
  end
  defp clear_unreads(socket) do
    Logger.warn "clear_unreads/1: default"
    socket
  end

  defp clear_unreads(room, %{assigns: assigns} = socket) do
    Logger.warn "room: #{inspect room}, assigns: #{inspect assigns}"
    ChannelService.set_has_unread(assigns.channel_id, assigns.user_id, false)
    push socket, "code:update", %{selector: ".link-room-" <> room,
      html: "has-unread", action: "removeClass"}
    push socket, "code:update", %{selector: ".link-room-" <> room,
      html: "has-alert", action: "removeClass"}
    push socket, "update:alerts", %{}
  end

  defp update_has_unread(%{id: channel_id, name: room},
    %{assigns: assigns} = socket) do
    has_unread = ChannelService.get_has_unread(channel_id, assigns.user_id)
    Logger.warn "has_unread: #{inspect has_unread}, channel_id: " <>
      "#{inspect channel_id}, assigns: #{inspect assigns}"
    unless has_unread do
      ChannelService.set_has_unread(channel_id, assigns.user_id, true)
      push socket, "code:update", %{selector: ".link-room-" <> room,
        html: "has-unread", action: "addClass"}
      push socket, "code:update", %{selector: ".link-room-" <> room,
        html: "has-alert", action: "addClass"}
      push socket, "update:alerts", %{}
    end
  end
  def new_subscription(_event, payload, socket) do
    channel_id = payload.channel_id
    user_id = socket.assigns.user_id

    socket
    |> update_rooms_list(user_id, channel_id)
    |> update_messages_header(user_id, channel_id, true)
  end

  def delete_subscription(_event, payload, socket) do
    channel_id = payload.channel_id
    user_id = socket.assigns.user_id
    socket
    |> update_rooms_list(user_id, channel_id)
    |> update_message_box(user_id, channel_id)
    |> update_messages_header(user_id, channel_id, false)
  end

  defp update_rooms_list(socket, user_id, channel_id) do
    Rebel.Query.update socket, :html,
      set: SideNavService.render_rooms_list(channel_id, user_id),
      on: "aside.side-nav .rooms-list"
    socket
  end

  defp update_message_box(socket, user_id, channel_id) do
    Rebel.Query.update socket, :html,
      set: MessageService.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
    socket
  end

  defp update_messages_header(socket, user_id, channel_id, show) do
    html = Phoenix.View.render_to_string MasterView, "favorite_icon.html",
      show: show, favorite: false
    Rebel.Core.async_js socket, ~s/$('section.messages-container .toggle-favorite').replaceWith('#{html}')/
    socket
  end

end
