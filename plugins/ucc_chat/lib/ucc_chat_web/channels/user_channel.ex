defmodule UccChatWeb.UserChannel do
  use UccLogger
  use UccChatWeb, :channel
  use UcxUcc
  use UcxUcc.UccPubSub
  use Rebel.Channel, name: "user", controllers: [
    UccChatWeb.ChannelController,
  ], intercepts: [
    "room:join",
    "room:leave",
    "room:mention",
    "user:state",
    "direct:new",
    "get:subscribed",
    "js:execjs",
    "webrtc:incoming_video_call",
    "webrtc:confirmed_video_call",
    "webrtc:declined_video_call",
  ]

  use UccChatWeb.RebelChannel.Macros

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import Rebel.Browser, warn: false
  import Ecto.Query, except: [update: 3]

  alias Phoenix.Socket.Broadcast
  alias UcxUcc.{Repo, Accounts}
  # alias UcxUcc.TabBar.Ftab
  alias Accounts.{Account, User}
  alias UccAdmin.AdminService
  alias UcxUccWeb.Endpoint
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.Schema.Subscription, as: SubscriptionSchema
  alias UccUiFlexTab.FlexTabChannel
  alias UccChatWeb.FlexBar.Form
  alias UccChat.{
    Subscription, ChannelService, Channel, Web.RoomChannel,
    SideNavService, ChannelService, SubscriptionService, InvitationService,
    UserService, EmojiService, Settings, MessageService
  }
  alias UccChatWeb.{RoomChannel, AccountView, UserSocket, MasterView}
  alias Rebel.SweetAlert

  alias UccWebrtcWeb.WebrtcChannel

  require UccChat.ChatConstants, as: CC

  onconnect :on_connect
  onload :page_loaded

  def on_connect(socket) do
    exec_js socket, "window.UccChat.run()"

    WebrtcChannel.on_connect(socket)
  end

  def page_loaded(socket) do
    Logger.info "page_loaded, assigns: #{inspect socket.assigns}"
    socket
  end

  def topic_click(socket, _sender) do
    Logger.debug "topic_click socket: #{inspect socket}"
    send socket.assigns.self, :do_topic_click
    # do_topic_click socket
    # SweetAlert.swal_modal socket, "My Title", "are you sure?", "warning",
    #   [showCancelButton: true, closeOnConfirm: false, closeOnCancel: false],
    #   confirm: fn result ->
    #     Logger.warn "sweet confirmed! #{inspect result}"
    #     SweetAlert.swal socket, "Confirmed!", "Your action was confirmed", "success",
    #       timer: 2000, showConfirmButton: false
    #     Logger.warn "sweet notice complete!"
    #   end,
    #   cancel: fn result ->
    #     Logger.warn "sweet canceled! result: #{inspect result}"
    #     SweetAlert.swal socket, "Canceled!", "Your action was canceled", "error",
    #       timer: 2000, showConfirmButton: false
    #     Logger.warn "sweet notice complete!"
    #   end
    # Logger.warn "res: #{inspect res}"
    socket
  end

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

  def join(CC.chan_user() <> _user_id = event, payload, socket) do
    trace(event, payload)
    send(self(), {:after_join, payload})
    super event, payload, FlexTabChannel.do_join(socket, event, payload)
  end

  def join(other, params, socket) do
    Logger.error "another join #{other}"
    super other, params, socket
  end

  def topic(_broadcasting, _controller, _request_path, conn_assigns) do
    conn_assigns[:current_user] |> Map.get(:id)
  end

  ###############
  # Outgoing Incoming Messages
    #   if data.media?.video
    #     icon = 'videocam'
    #     title = "Direct video call from #{fromUsername}"
    #   else
    #     icon = 'phone'
    #     title = "Direct audio call from #{fromUsername}"
    # else
    #   if data.media?.video
    #     icon = 'videocam'
    #     title = "Group video call from #{subscription.name}"
    #   else
    #     icon = 'phone'
    #     title = "Group audio call from #{subscription.name}"

    # swal
    #   title: "<i class='icon-#{icon} alert-icon success-color'></i>#{title}"
    #   text: "Do you want to accept?"
    #   html: true
    #   showCancelButton: true
    #   confirmButtonText: "Yes"
    #   cancelButtonText: "No"
  def handle_out("webrtc:" <> event, payload, socket) do
    apply WebrtcChannel, String.to_atom(event), [payload, socket]
  end

  # def handle_out("webrtc:incoming_video_call" = ev, payload, socket) do
  #   trace ev, payload
  #   trace ev, socket.assigns
  #   title = "Direct video call from #{payload[:username]}"
  #   icon = "videocam"
  #   SweetAlert.swal_modal socket, ~s(<i class="icon-#{icon} alert-icon success-color"></i>#{title}), "Do you want to accept?", nil,
  #     [html: true, showCancelButton: true, closeOnConfirm: true, closeOnCancel: true],
  #     confirm: fn result ->
  #       Logger.warn "sweet confirmed! #{inspect result}"
  #       UcxUcc.Endpoint.broadcast "user:" <>  payload[:user_id], "webrtc:confirmed_video_call",
  #         %{user_id: socket.assigns.user_id}
  #     end,
  #     cancel: fn result ->
  #       UcxUcc.Endpoint.broadcast "user:" <>  payload[:user_id], "webrtc:declined_video_call",
  #         %{user_id: socket.assigns.user_id}
  #       Logger.warn "sweet canceled! result: #{inspect result}"
  #     end

  #   {:noreply, socket}
  # end

  # def handle_out(ev = "webrtc:confirmed_video_call", payload, socket) do
  #   trace ev, payload

  #   {:noreply, socket}
  # end

  # def handle_out(ev = "webrtc:declined_video_call", payload, socket) do
  #   trace ev, payload
  #   {:noreply, socket}
  # end

  def handle_out("js:execjs" = ev, payload, socket) do
    trace ev, payload
    _ = ev
    _ = payload
    case exec_js socket, payload[:js] do
      {:ok, result} ->
        send payload[:sender], {:response, result}
      {:error, error} ->
        send payload[:sender], {:error, error}
    end
    {:noreply, socket}
  end

  def handle_out("get:subscribed" = ev, msg, socket) do
    trace ev, msg
    _ = ev
    _ = msg

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
    _ = ev
    _ = msg
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
    _ = ev
    _ = params
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
    _ = ev
    _ = params
    {:noreply, socket}
  end

  def handle_in("side_nav:open" = ev, %{"page" => "account"} = params,
    socket) do
    trace ev, params
    _ = ev
    _ = params

    user = Helpers.get_user!(socket)
    account_cs = Account.changeset(user.account, %{})
    html = Helpers.render(AccountView, "account_preferences.html",
      user: user, account_changeset: account_cs)
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}

    html = Helpers.render(AccountView, "account_flex.html")
    {:reply, {:ok, %{html: html}}, socket}
  end
  # def handle_in("side_nav:open" = ev, %{"page" => "admin"} = params, socket) do
  #   trace ev, params
  #   _ = ev
  #   _ = params

  #   user = Helpers.get_user!(socket)

  #   html = AdminService.render_info(user)
  #   push socket, "code:update", %{html: html, selector: ".main-content",
  #     action: "html"}

  #   html = Helpers.render(UccAdminWeb.AdminView, "admin_flex.html",
  #     user: user)
  #   {:reply, {:ok, %{html: html}}, socket}
  # end

  def handle_in("side_nav:more_channels" = ev, params, socket) do
    _ = ev
    _ = params
    trace ev, params

    html = SideNavService.render_more_channels(socket.assigns.user_id)
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("side_nav:more_users" = ev, params, socket) do
    trace ev, params
    _ = ev
    _ = params

    html = SideNavService.render_more_users(socket.assigns.user_id)
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("side_nav:close" = ev, params, socket) do
    trace ev, params
    _ = ev
    _ = params

    {:noreply, socket}
  end

  def handle_in("account:preferences:save" = ev, params, socket) do
    trace ev, params, "assigns: #{inspect socket.assigns}"
    _ = ev
    _ = params
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
    _ = ev
    _ = params
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
    _ = ev
    _ = params

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
    _ = ev
    _ = params
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
    _ = ev
    _ = params
    user = Helpers.get_user! socket
    html = AdminService.render user, link, "#{link}.html"
    push socket, "code:update", %{html: html, selector: ".main-content", action: "html"}
    exec_js socket, "Rebel.set_event_handlers('.main-content')"
    {:noreply, socket}
  end

  def handle_in(ev = "admin_link:click:webrtc" , params, socket) do
    link = "webrtc"
    trace ev, params
    _ = ev
    _ = params
    user = Helpers.get_user! socket
    html = AdminService.render user, link, "#{link}.html"
    push socket, "code:update", %{html: html, selector: ".main-content",
      action: "html"}
    {:noreply, socket}
  end

  def handle_in(ev = "admin:" <> link, params, socket) do
    trace ev, params
    _ = ev
    AdminService.handle_in(link, params, socket)
  end

  # def handle_in(ev = "flex:member-list:" <> action, params, socket) do
  #   debug ev, params
  #   FlexBarService.handle_in action, params, socket
  # end

  def handle_in(ev = "update:currentMessage", params, socket) do
    trace ev, params
    _ = ev
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
    _ = ev
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
    _ = ev
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

  def handle_in("webrtc:device_manager_init", payload, socket) do
    WebrtcChannel.device_manager_init(socket, payload)
  end

  def handle_in(ev = "webrtc:incoming_video_call", payload, socket) do

    trace ev, payload

    {:noreply, socket}
  end

  # default unknown handler
  def handle_in(event, params, socket) do
    Logger.warn "UserChannel.handle_in unknown event: #{inspect event}, " <>
      "params: #{inspect params}"
    {:noreply, socket}
  end


  defp do_topic_click(socket) do
    SweetAlert.swal_modal socket, "My Title", "are you sure?", nil,
      [showCancelButton: true, closeOnConfirm: false, closeOnCancel: false],
      confirm: fn _result ->
        SweetAlert.swal socket, "Confirmed!", "Your action was confirmed", "success",
          timer: 2000, showConfirmButton: false
      end,
      cancel: fn _result ->
        # Logger.warn "sweet canceled! result: #{inspect result}"
        SweetAlert.swal socket, "Canceled!", "Your action was canceled", "error",
          timer: 2000, showConfirmButton: false
      end
  end
  ###############
  # Info messages

  def handle_info(:do_topic_click, socket) do
    do_topic_click(socket)
    noreply socket
  end
  def handle_info({"webrtc:incoming_video_call" = ev, payload}, socket) do

    trace ev, payload
    trace ev, socket.assigns

    title = "Direct video call from #{payload[:username]}"
    icon = "videocam"
    # SweetAlert.swal_modal socket, "<i class='icon-#{icon} alert-icon success-color'></i>#{title}", "Do you want to accept?", "warning",
    # SweetAlert.swal_modal socket, title, "Do you want to accept?", "warning",
    SweetAlert.swal_modal socket, ~s(<i class="icon-#{icon} alert-icon success-color"></i>#{title}), "Do you want to accept?", nil,
      [html: true, showCancelButton: true, closeOnConfirm: true, closeOnCancel: true],
      confirm: fn result ->
        # Logger.warn "sweet confirmed! #{inspect result}"

        # SweetAlert.swal socket, "Confirmed!", "Your action was confirmed", "success",
        #   timer: 2000, showConfirmButton: false
      end,
      cancel: fn result ->
        # Logger.warn "sweet canceled! result: #{inspect result}"
        # SweetAlert.swal socket, "Canceled!", "Your action was canceled", "error",
        #   timer: 2000, showConfirmButton: false
        # Logger.warn "sweet notice complete!"
      end

    {:noreply, socket}
  end


  def handle_info({:after_join, params}, socket) do
    :erlang.process_flag(:trap_exit, true)

    trace "after_join", socket.assigns, inspect(params)
    user_id = socket.assigns.user_id
    # require IEx
    # IEx.pry

    channel_name =
      case params["channel_id"] do
        id when id in ["", nil] ->
          "lobby"
        channel_id ->
          channel_id
          |> Channel.get
          |> Map.get(:name)
      end

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
      |> assign(:room, channel_name)
      |> assign(:self, self())

    socket =
      Repo.all(from s in SubscriptionSchema, where: s.user_id == ^user_id,
        preload: [:channel, {:user, :roles}])
      |> Enum.map(&(&1.channel.name))
      |> subscribe(socket)

    subscribe_callback "user:" <> user_id, "room:join",
      {FlexTabChannel, :room_join}
    subscribe_callback "user:" <> user_id, "new:subscription",
      :new_subscription
    subscribe_callback "user:" <> user_id, "delete:subscription",
      :delete_subscription
    subscribe_callback "user:" <> user_id, "room:update",
      :room_update
    subscribe_callback "user:" <> user_id, "webrtc:offer", :webrtc_offer
    subscribe_callback "user:" <> user_id, "webrtc:answer", {WebrtcChannel, :webrtc_answer}
    subscribe_callback "user:" <> user_id, "webrtc:leave", {WebrtcChannel, :webrtc_leave}
    # TODO: add Hooks for this
    # subscribe_callback "phone:presence", "presence:change", :phone_presence_change
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
      Logger.debug "in the room ... #{assigns.user_id}, room: #{inspect room}"
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

  def handle_info(%Broadcast{event: "user:action" = event,
    payload: %{action: "unhide"} = payload}, %{assigns: assigns} = socket) do

    trace event, payload, "assigns: #{inspect assigns}"

    UserSocket.push_rooms_list_update(socket, payload.channel_id,
      payload.user_id)

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "user:entered" = event,
    payload: %{user_id: user_id} = payload},
    %{assigns: %{user_id: user_id} = assigns} = socket) do

    trace event, payload, "assigns: #{inspect assigns}"

    channel_id = payload[:channel_id]
    socket = %{assigns: _assigns} = assign(socket, :channel_id, channel_id)

    UccPubSub.broadcast "user:" <> assigns.user_id, "room:join",
      %{channel_id: channel_id}

    {:noreply, socket}
  end

  def hadnle_info(%Broadcast{event: "user:entered"}, socket) do
    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "room:delete" = event,
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

  # Default broadcast case to ignore messages we are not interested in
  def handle_info(%Broadcast{} = broadcast, socket) do
    Logger.warn "broadcast: " <> inspect(broadcast)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    {:noreply, socket}
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

  handle_callback("user:" <>  _user_id)

  def handle_info({"phone:presence", "presence:change", meta, {mod, fun}} = payload, socket) do
    Logger.info "payload: #{inspect payload}"
    apply(mod, fun, ["presence:change", meta, socket])
    {:noreply, socket}
  end

  def handle_info({:EXIT, _, :normal}, socket) do
    {:noreply, socket}
  end

  def handle_info(payload, socket) do
    Logger.error "default handle info payload: #{inspect payload}"
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    UccPubSub.unsubscribe "user:" <> socket.assigns[:user_id]
    :ok
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
    # Logger.warn "channels: #{inspect channels}"
    # Logger.warn "subscribed: #{inspect socket.assigns[:subscribed]}"
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
    # Logger.warn "clear_unreads/1: channel_id: #{inspect channel_id}, " <>
    #   "socket.assigns.user_id: #{inspect socket.assigns.user_id}"
    channel_id
    |> Channel.get
    |> Map.get(:name)
    |> clear_unreads(socket)
  end
  defp clear_unreads(socket) do
    Logger.debug "clear_unreads/1: default"
    socket
  end

  defp clear_unreads(room, %{assigns: assigns} = socket) do
    # Logger.warn "room: #{inspect room}, assigns: #{inspect assigns}"
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
    Logger.debug "has_unread: #{inspect has_unread}, channel_id: " <>
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

  # TOOD: this needs to be moved like the video stuff
  def start_audio_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.debug "start audio curr_id: #{current_user_id}, user_id: #{user_id}"
    socket
  end

  def add_private(socket, sender) do
    trace "add_private", sender
    username = exec_js! socket, ~s{$('#{this(sender)}').parent().data('username')}
    redirect_to socket, "/direct/#{username}"
  end

  def new_subscription(_event, payload, socket) do
    channel_id = payload.channel_id
    user_id = socket.assigns.user_id

    socket
    |> update_rooms_list(user_id, channel_id)
    |> update_messages_header(true)
  end

  def delete_subscription(_event, payload, socket) do
    channel_id = payload.channel_id
    user_id = socket.assigns.user_id
    socket
    |> update_rooms_list(user_id, channel_id)
    |> update_message_box(user_id, channel_id)
    |> update_messages_header(false)
  end

  def room_update(_event, payload, socket) do
    trace "room_update", payload
    channel_id = payload.channel_id
    user_id = socket.assigns.user_id
    socket
    |> do_room_update(payload[:field], user_id, channel_id)
  end

  defp do_room_update(socket, {:name, new_room}, user_id, channel_id) do
    room = socket.assigns.room
    RoomChannel.broadcast_name_change(room, new_room, user_id, channel_id)
    # broadcast message header on room channel
    # broadcast room entry on user channel
    socket
  end
  defp do_room_update(socket, {:topic, data}, _user_id, _channel_id) do
    RoomChannel.broadcast_room_field(socket.assigns.room, "topic", data)
    socket
  end
  defp do_room_update(socket, {:description, data}, _user_id, _channel_id) do
    RoomChannel.broadcast_room_field(socket.assigns.room, "description", data)
    socket
  end
  defp do_room_update(socket, {:type, _}, _user_id, _channel_id) do
    # breoadcast message header on room channel
    # broadcast room entry on user channel
    # broadcast message box on room channel
    socket
  end
  defp do_room_update(socket, {:read_only, _}, _user_id, _channel_id) do
    # broadcast message box on room channel
    socket
  end
  defp do_room_update(socket, {:archived, _}, _user_id, _channel_id) do
    # broadcast room entry on user channel
    # broadcast message box on room channel
    socket
  end
  defp do_room_update(socket, field, _user_id, _channel_id) do
    Logger.warn "field: #{inspect field}, assigns: #{inspect socket.assigns}"
    socket
  end

  defp update_rooms_list(socket, user_id, channel_id) do
    update socket, :html,
      set: SideNavService.render_rooms_list(channel_id, user_id),
      on: "aside.side-nav .rooms-list"
    socket
  end

  def webrtc_offer(event, payload, socket) do
    trace event, payload, inspect(socket.assigns)
    _ = event
    IO.inspect Map.get(payload, :name), label: "keys"
    socket
  end

  # defp broadcast_rooms_list(socket, user_id, channel_id) do
  #   socket
  # end

  defp update_message_box(socket, user_id, channel_id) do
    update socket, :html,
      set: MessageService.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
    socket
  end

  defp update_messages_header(socket, show) do
    html = Phoenix.View.render_to_string MasterView, "favorite_icon.html",
      show: show, favorite: false
    async_js socket,
      ~s/$('section.messages-container .toggle-favorite').replaceWith('#{html}')/
    socket
  end

  def video_stop(socket, sender) do
    _ = sender
    trace "video_stop", sender
    exec_js(socket, "window.WebRTC.hangup")
    execute(socket, :click, on: ".tab-button.active")
  end

  def phone_presence_change(_event, %{state: state, username: username} = _payload, socket) do
    Logger.info "state change #{inspect state}, username: #{username}" #, assigns: " <> inspect(socket.assigns)
     # exec_js socket, ~s/$('[data-phone-status="#{username}"]').removeClass('phone-idle').addClass('phone-busy')/
    exec_js socket, set_data_status_js(username, state)
     #{}~s/$('[data-phone-status="#{username}"]').data('status', '#{state}')/
    socket
  end

  defp set_data_status_js(username, state) do
    """
    var e = document.querySelectorAll('[data-phone-status="#{username}"]');
    for(var i = 0; i < e.length; i++) {e[i].dataset.status = '#{state}'}
    console.log('done...');
    """
    |> String.replace("\n", "")
  end
  def click_status(socket, sender) do
    Logger.error "Click Status #{inspect sender}"
    user_id = socket.assigns.user_id
    status = sender["dataset"]["status"] || ""
    Logger.error "handle status #{status}"
    UccPubSub.broadcast "status:" <> user_id, "set:" <> status, sender["dataset"]
    socket
  end

  def phone_call(socket, sender) do
    Logger.warn "click to call... #{inspect sender}"
    socket
  end

  defdelegate flex_tab_click(socket, sender), to: FlexTabChannel
  defdelegate flex_tab_open(socket, sender), to: FlexTabChannel
  defdelegate flex_call(socket, sender), to: FlexTabChannel
  defdelegate flex_close(socket, sender), to: FlexTabChannel
  defdelegate flex_form(socket, sender), to: Form
  defdelegate flex_form_save(socket, sender), to: Form
  defdelegate flex_form_cancel(socket, sender), to: Form
  defdelegate flex_form_toggle(socket, sender), to: Form
  defdelegate flex_form_select_change(socket, sender), to: Form
  # defdelegate click_admin(socket, sender), to: UccAdminWeb.AdminChannel

  defdelegateadmin :click_admin
  defdelegateadmin :admin_link
  defdelegateadmin :admin_flex

end
