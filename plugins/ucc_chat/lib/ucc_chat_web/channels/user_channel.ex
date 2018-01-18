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
    "update:room-icon",
    "update:room-visibility",
    "get:subscribed",
    "js:execjs",
    "webrtc:incoming_video_call",
    "webrtc:confirmed_video_call",
    "webrtc:declined_video_call",
    "webrtc:leave",
    "get",
  ]

  use UccChatWeb.RebelChannel.Macros

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import Rebel.Browser, warn: false
  import Ecto.Query, except: [update: 3]

  alias Phoenix.Socket.Broadcast
  alias UcxUcc.{Repo, Accounts, Hooks, TabBar}
  # alias UcxUcc.TabBar.Ftab
  alias Accounts.{Account, User}
  alias UccAdmin.AdminService
  alias UcxUccWeb.Endpoint
  alias UccChat.ServiceHelpers, as: Helpers
  alias UccChat.Schema.Subscription, as: SubscriptionSchema
  alias UccUiFlexTab.FlexTabChannel
  alias UccChatWeb.FlexBar.Form
  alias UccChat.{
    Subscription, ChannelService, Channel, Web.RoomChannel, Message,
    SideNavService, ChannelService, SubscriptionService, InvitationService,
    UserService, EmojiService, Settings, MessageService, Mention
  }
  alias UccChatWeb.{RoomChannel, AccountView, UserSocket, MasterView, FlexBarView}
  alias Rebel.SweetAlert
  alias UccWebrtcWeb.WebrtcChannel
  alias UccChatWeb.RebelChannel.Client
  alias UccChatWeb.RoomChannel.Channel, as: WebChannel
  alias UcxUcc.UccPubSub
  alias UcxUccWeb.Query

  require UccChat.ChatConstants, as: CC

  onconnect :on_connect
  onload :page_loaded

  def on_connect(socket) do
    broadcast_js socket, "window.UccChat.run()"

    WebrtcChannel.on_connect(socket)
  end

  def page_loaded(socket) do
    # Logger.info "page_loaded, assigns: #{inspect socket.assigns}"
    socket
  end

  def join_room(user_id, room) do
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "room:join",
      %{room: room, user_id: user_id})
  end

  def leave_room(user_id, room) do
    Endpoint.broadcast!(CC.chan_user() <> "#{user_id}", "room:leave",
      %{room: room, user_id: user_id})
  end

  def notify_mention(%{user_id: user_id, channel_id: channel_id} = mention, body) do
    mention = Mention.preload_schema mention, [message: :user]
    Endpoint.broadcast(CC.chan_user() <> "#{user_id}", "room:mention",
      %{channel_id: channel_id, user_id: user_id, body: body, mention: mention})
  end

  def user_state(user_id, state) do
    Endpoint.broadcast(CC.chan_user() <> "#{user_id}", "user:state",
      %{state: state})
  end

  @doc """
  API to get internal state from a channel.

  Used for debugging purposes.
  """
  @spec get(any, String.t) :: any
  def get(item, user_id) do
    Endpoint.broadcast(CC.chan_user() <> "#{user_id}", "get", %{item: item, caller: self()})
    receive do
      {:get_response, response} -> {:ok, response}
    after
      1_500 -> {:error, :timeout}
    end
  end

  def join(CC.chan_user() <> _user_id = event, payload, socket) do
    trace(event, payload)
    send(self(), {:after_join, payload})
    super event, payload, FlexTabChannel.do_join(socket, event, payload)
  end

  def join(other, params, socket) do
    # Logger.error "another join #{other}"
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

   def handle_out("webrtc:leave" = ev, payload, socket) do
     trace ev, payload
     broadcast_js socket, ~s/$('.webrtc-video button.stop-call').click()/
     {:noreply, socket}
   end

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

  # Generic handler for retrieving internal information from a channel.
  # This is only for debugging purposes.
  def handle_out("get", payload, socket) do
    response =
      case payload[:item] do
        :assigns -> socket.assigns
        :socket -> socket
        :pid -> self()
        {:assigns, field} -> Map.get(socket.assigns, field)
        _ -> :invalid
      end
    send payload[:caller], {:get_response, response}
    {:noreply, socket}
  end

  def handle_out("js:execjs" = ev, payload, socket) do
    trace ev, payload

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

  def handle_out("update:room-icon", payload, socket) do
    icon = String.replace(payload.icon_name, ~r/^icon-/, "")
    Client.broadcast_room_icon(socket, payload.room_name, icon)
    {:noreply, socket}
  end

  def handle_out("update:room-visibility", payload, socket) do
    Client.broadcast_room_visibility(socket, payload, payload.visible)
    {:noreply, socket}
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

  def more_channels(socket, _sender, client \\ Client) do
    client.more_channels socket, SideNavService.render_more_channels(socket.assigns.user_id)
    socket
  end

  def push_update_direct_message(msg, socket) do
    Process.send_after self(),
      {:update_direct_message, msg, socket.assigns.user_id}, 250
    socket
  end

  ###############
  # Incoming Messages

  def handle_in("notification:click", params, socket) do
    message = Message.get params["message_id"]
    if params["channel_id"] == socket.assigns.channel_id do
      broadcast_js socket, ~s/UccChat.roomHistoryManager.scroll_to_message('#{message.timestamp}')/
    else
      room = params["channel_name"]
      broadcast_js socket, ~s/$('aside.side-nav a.open-room[data-room="#{room}"]').click()/

      # TODO: This is a hack. We should have a notification when the room is loaded and then run the JS below.
      spawn fn ->
        Process.sleep 3500
        broadcast_js socket, ~s/UccChat.roomHistoryManager.scroll_to_message('#{message.timestamp}')/
      end
    end

    {:noreply, socket}
  end

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

    Client.update_main_content_html socket, AccountView,
      "account_preferences.html",
      user: user, account_changeset: account_cs

    html = Helpers.render(AccountView, "account_flex.html")
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
    assigns = socket.assigns

    UccUiFlexTab.FlexTabChannel.flex_close socket, %{}

    assigns.user_id
    |> UcxUcc.TabBar.get_ftabs
    |> Enum.find(fn {tab_name, _} -> String.starts_with?(tab_name, "admin_") end)
    |> case do
        {tab_name, _} ->
          Logger.warn "found open admin tab: " <> tab_name
          module =
            "admin_user_info"
            |> TabBar.get_button
            |> Map.get(:module)

          module.close socket, %{}
          TabBar.close_ftab assigns.user_id, assigns.channel_id
        _ ->
          :ok
    end

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

  def handle_in("account:phone:save" = ev, params, socket) do
    trace ev, params, "assigns: #{inspect socket.assigns}"

    # TODO: Need to validate parameters to ensure they were not changed on
    #       the way from the client to the server. This includes the user_id
    #       and the phone number id.
    {id, phone_number_params} =
      params
      |> Helpers.normalize_form_params
      |> Map.get("phone_number")
      |> Map.pop("id")

    resp =
      case id do
        nil ->
          phone_number_params
          |> Map.put("user_id", socket.assigns.user_id)
          |> Map.put("primary", true)
          |> Map.put("extension", %{user_id: socket.assigns.user_id, default: true})
          |> Accounts.create_phone_number
          |> case do
            {:ok, phone_number} ->
              if phone_number.primary do
                UccPubSub.broadcast "phone_number", "create", %{
                  number: phone_number.number,
                  user_id: socket.assigns.user_id,
                  username: socket.assigns.username
                }
              end
              # Logger.warn inspect(socket.assigns)

              {:ok, %{success: ~g"Phone Number created successfully"}}
            {:error, cs} ->
              Logger.error "cs.errors: #{inspect cs.errors}"
              {:ok, %{error: ~g"There a problem creating your phone number."}}
          end
        id ->
          id
          |> Accounts.get_phone_number!
          |> Accounts.update_phone_number(phone_number_params)
          |> case do
            {:ok, phone_number} ->
              if phone_number.primary do
                UccPubSub.broadcast "phone_number", "update", %{
                  number: phone_number.number,
                  user_id: socket.assigns.user_id,
                  username: socket.assigns.username
                }
              end
              # Logger.warn inspect(socket.assigns)
              {:ok, %{success: ~g"Phone Number updated successfully"}}
            {:error, cs} ->
              Logger.error "cs.errors: #{inspect cs.errors}"
              {:ok, %{error: ~g"There a problem updating your phone number."}}
          end
      end

    {:reply, resp, socket}
  end

  def handle_in("account:phone:delete", params, socket) do

    user_id = socket.assigns.user_id
    phone_number =
      params
      |> Helpers.normalize_form_params()
      |> Map.get("phone_number")
      |> Map.get("id")
      |> Accounts.get_phone_number!

    resp =
      case phone_number.user_id do
        ^user_id ->
          case Accounts.delete_phone_number(phone_number) do
            {:ok, _} ->
              if phone_number.primary do
                UccPubSub.broadcast "phone_number", "delete", %{
                  number: phone_number.number,
                  user_id: socket.assigns.user_id,
                  username: socket.assigns.username
                }
              end

              {:ok, %{success: ~g"Phone Number deleted successfully."}}
            {:error, _} ->
              {:ok, %{error: ~g"There was a problem deleting the phone number!"}}
          end
        _ ->
          {:ok, %{error: ~g"You don't have permission to delete that phone number!"}}
      end

    {:reply, resp, socket}
  end

  @links ~w(preferences profile)
  def handle_in(ev = "account_link:click:" <> link, params, socket) when link in @links do

    trace ev, params

    user = Accounts.get_user(socket.assigns.user_id,
      preload: Hooks.user_preload([:account, :roles, user_roles: :role, phone_numbers: :label]))

    user_cs = User.changeset(user, %{})
    account_cs = Account.changeset(user.account, %{})

    Client.update_main_content_html socket, AccountView, "account_#{link}.html",
        user: user, account_changeset: account_cs, user_changeset: user_cs

    {:noreply, socket}
  end

  def handle_in(ev = "account_link:click:phone", params, socket) do

    trace ev, params

    user = Accounts.get_user(socket.assigns.user_id,
      preload: Hooks.user_preload([:account, :roles, user_roles: :role, phone_numbers: :label]))

    labels = Enum.map Accounts.list_phone_number_labels, & {String.to_atom(&1.name), &1.id}

    phone_cs =
      case user.phone_numbers do
        [] ->
          work = Enum.find labels |> IO.inspect(label: "labels"), & elem(&1, 0) == :Work
          Accounts.change_phone_number(%{primary: true, label_id: elem(work, 1)})
        [pn | _] ->
          Accounts.change_phone_number(pn, %{})
      end
    user_cs = Accounts.change_user(user)

    Client.update_main_content_html socket, AccountView, "account_phone.html",
        user: user, phone_number_changeset: phone_cs, labels: labels, user_changeset: user_cs

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
    broadcast_js socket, "Rebel.set_event_handlers('.main-content')"
    {:noreply, socket}
  end

  def handle_in(ev = "admin_link:click:webrtc" , params, socket) do
    link = "webrtc"
    trace ev, params

    user = Helpers.get_user! socket

    update socket, :html,
      set: AdminService.render(user, link, "#{link}.html"),
      on: ".main-content"

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

  ###############
  # Info messages

  def handle_info({"webrtc:incoming_video_call" = ev, payload}, socket) do

    trace ev, payload
    trace ev, socket.assigns

    title = "Direct video call from #{payload[:username]}"
    icon = "videocam"
    # SweetAlert.swal_modal socket, "<i class='icon-#{icon} alert-icon success-color'></i>#{title}", "Do you want to accept?", "warning",
    # SweetAlert.swal_modal socket, title, "Do you want to accept?", "warning",
    SweetAlert.swal_modal socket, ~s(<i class="icon-#{icon} alert-icon success-color"></i>#{title}), "Do you want to accept?", nil,
      [html: true, showCancelButton: true, closeOnConfirm: true, closeOnCancel: true],
      confirm: fn _result ->
        # Logger.warn "sweet confirmed! #{inspect result}"

        # SweetAlert.swal socket, "Confirmed!", "Your action was confirmed", "success",
        #   timer: 2000, showConfirmButton: false
        true
      end,
      cancel: fn _result ->
        # Logger.warn "sweet canceled! result: #{inspect result}"
        # SweetAlert.swal socket, "Canceled!", "Your action was canceled", "error",
        #   timer: 2000, showConfirmButton: false
        # Logger.warn "sweet notice complete!"
        true
      end

    {:noreply, socket}
  end


  def handle_info({:after_join, params}, socket) do
    :erlang.process_flag(:trap_exit, true)

    trace "after_join", socket.assigns, inspect(params)
    user_id = socket.assigns.user_id

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
    subscribe_callback "user:all", "callback", :user_all_event

    # TODO: Add hooks for this
    subscribe_callback "user:" <> user_id, "presence:change", {UcxPresenceWeb.Channel.Presence, :presence_change}
    subscribe_callback "user:all", "status_message:update", :status_message_update

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
      # Logger.debug "in the room ... #{assigns.user_id}, room: #{inspect room}"
      if channel.id != assigns.channel_id or assigns.user_state == "idle" do
        if channel.type == 2 do
          msg =
            if payload[:body] do
              %{body: payload[:body], username: assigns.username, message: payload[:message]}
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

    update_rooms_list(socket, socket.assigns.user_id, payload.channel_id)

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "user:entered" = event,
    payload: %{user_id: user_id} = payload},
    %{assigns: %{user_id: user_id} = assigns} = socket) do

    trace event, payload, "assigns: #{inspect assigns}"

    channel_id = payload[:channel_id]
    new_channel = Channel.get(channel_id)
    socket = %{assigns: _assigns} =
      socket
      |> assign(:channel_id, channel_id)
      |> assign(:last_channel_id, assigns[:channel_id])
      |> assign(:room, new_channel.name)

    UccPubSub.broadcast "user:" <> assigns.user_id, "room:join",
      %{channel_id: channel_id}

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "user:entered"}, socket) do
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

  # def handle_info(%Broadcast{topic: "room:" <> room, event: "broadcastjs",
  #   payload: %{js: js} = payload}, socket) do

  #   trace "broadcast room:" <> room <> ", event: broadcastjs", payload
  #   # next, update sidebar if subscribed
  #   if room in socket.assigns.subscribed do
  #     exec_js socket, js
  #   end

  #   {:noreply, socket}
  # end

  # Default broadcast case to ignore messages we are not interested in
  def handle_info(%Broadcast{}, socket) do
    # Logger.warn "broadcast: " <> inspect(broadcast)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
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

    with sub <- Subscription.get_by(channel_id: channel_id,
                    user_id: user_id),
         open  <- Map.get(sub, :open),
         false <- socket.assigns.user_state == "active" and open,
         count <- ChannelService.get_unread(channel_id, user_id) do
      push(socket, "room:mention", %{room: channel.name, unread: count})

      if body do
        body = Helpers.strip_tags body
        user = Helpers.get_user user_id
        handle_notifications socket, user, channel, %{body: body,
          username: socket.assigns.username, mention: payload[:mention]}
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

    # Logger.warn "update_direct_message: " <> inspect(payload)

    %{channel_id: channel_id, msg: msg} = payload
    channel = Channel.get!(channel_id)

    with [sub] <- Repo.all(Subscription.get(channel_id, user_id)),
         # _ <- Logger.warn("update_direct_message unread: #{sub.unread}"),
         open  <- Map.get(sub, :open),
         # _ <- Logger.warn("open: #{inspect open}"),
         false <- socket.assigns.user_state == "active" and open,
         count <- ChannelService.get_unread(channel_id, user_id) do
      push(socket, "room:mention", %{room: channel.name, unread: count})

      # Logger.warn "msg: " <> inspect(msg)
      if msg do
        user = Helpers.get_user(user_id)
        handle_notifications socket, user, channel,
          update_in(msg, [:body], &Helpers.strip_tags/1)
      end
    end
    {:noreply, socket}
  end

  handle_callback("user:" <>  _user_id)
  handle_callback("user:all")

  def handle_info({"phone:presence", "presence:change", meta, {mod, fun}} = _payload, socket) do
    # Logger.info "payload: #{inspect payload}"
    apply(mod, fun, ["presence:change", meta, socket])
    {:noreply, socket}
  end

  def handle_info({:EXIT, _, :normal}, socket) do
    {:noreply, socket}
  end

  def handle_info(payload, socket) do
    Logger.warn "default handle info payload: #{inspect payload}"
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    UccPubSub.unsubscribe "user:" <> socket.assigns[:user_id]
    :ok
  end

  ###############
  # Helpers

  defp handle_notifications(socket, user, channel, payload, client \\ UccChatWeb.Client)
  defp handle_notifications(socket, user, channel, payload, client) do
    message = if mention = payload[:mention], do: mention.message, else: payload[:message]
    payload = case UccChat.Settings.get_new_message_sound(user, channel.id) do
      nil -> payload
      sound -> Map.put(payload, :sound, sound)
    end

    if UccSettings.enable_desktop_notifications() do
      client.desktop_notify(socket,
        message.user.username,
        payload.body,
        Message.preload_schema(message, [:channel]),
        Settings.get_desktop_notification_duration(user, channel))
    else
      push socket, "notification:new", Map.put(payload, :badges_only, true)
    end

    if sound = payload[:sound] do
      # Logger.warn "sound: " <> inspect(sound)
      client.notify_audio(socket, sound)
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
    Rebel.Query.update socket, :html, set: html, on: ".rooms-list"
    socket
  end

  defp clear_unreads(%{assigns: %{channel_id: ""}} = socket) do
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

    broadcast_js socket, """
      $('link-room-#{room}').removeClass('has-unread')
        .removeClass('has-alert');
      """ |> String.replace("\n", "")

    push socket, "update:alerts", %{}
  end

  defp update_has_unread(%{id: channel_id, name: room},
    %{assigns: assigns} = socket) do
    has_unread = ChannelService.get_has_unread(channel_id, assigns.user_id)
    Logger.debug fn -> "has_unread: #{inspect has_unread}, channel_id: " <>
      "#{inspect channel_id}, assigns: #{inspect assigns}" end
    unless has_unread do
      ChannelService.set_has_unread(channel_id, assigns.user_id, true)

      broadcast_js socket,
        "$('.link-room-#{room}').addClass('has-unread').addClass('has-alert');"
      push socket, "update:alerts", %{}
    end
  end

  def drop_notify_click(socket, sender) do
    # Logger.info "sender: " <> inspect(sender)
    dataset = sender["dataset"]
    id = dataset["id"]
    channel = dataset["channel"]
    # Logger.info inspect({id, channel})
    if id == "answer_call" && channel do
      # Logger.info "answering #{dataset["channel"]}"
      UcxPresence.Server.answer_call dataset["channel"]
    end
    socket
  end
  def drop_notify_cancel(socket, sender) do
    broadcast_js socket, """
      var elem = $('#{this(sender)}').closest('.notice');
      elem.animate({
        height: "0px",
        'font-size': "0px"
      }, 500, function() {
        elem.delete();
      });
      """ |> String.replace("\n", " ")

    socket
  end

  #################################
  # Status Messages Implementation
  #

  def change_status_message(socket, sender) do
    Logger.debug fn -> inspect(sender) end
    user = Accounts.get_user(socket.assigns.user_id, preload: [:account])
    account = user.account

    case sender["value"] do
      "__new__" ->
        account
        |> push_status_message_select(socket)
        |> show_status_message_input()
        |> async_js(~s/$('.status-message-input input').focus();/)

      "__clear__" ->
        case UcxUcc.Accounts.update_account(account, %{status_message: ""}) do
          {:ok, account} ->
            Client.toastr(socket, :success, ~g(Your status message as been cleared))
            account
          {:error, _} ->
            Client.toastr socket, :error, ~g(Problem updating clearing your status message)
            account
        end
        |> push_status_message_select(socket)
        |> Rebel.Query.execute(:click, on: ".account-box.active")
        |> broadcast_status_message(user.username, "")

      "" ->
        if sender["event"]["type"] == "click" do
          async_js socket, "$('.status-message-input input').change();"
        else
          account
          |> push_status_message_select(socket)
          |> Rebel.Query.execute(:click, on: ".account-box.active")
          |> show_status_message_select()
        end

      message  ->
        message = String.trim(message)
        user = Accounts.get_user socket.assigns.user_id, preload: [:account]
        case UccChat.Accounts.update_status_message(user.account, message) do
          {:ok, _} ->
            socket
            |> Client.toastr(:success, ~g(Your status message was updated))
            |> broadcast_status_message(user.username, message)
          {:error, _} ->
            Client.toastr socket, :error, ~g(Problem updating your status message)
        end
        socket
        |> Rebel.Query.execute(:click, on: ".account-box.active")
        |> show_status_message_select()
    end

    socket
  end

  def cancel_status_message(socket, sender) do
    Logger.debug fn -> inspect(sender) end
    async_js socket, "$('.status-message-input').hide(); $('.status-message-select').show();"
    socket
  end

  defp push_status_message_select(account, socket) do
    html =
      Phoenix.View.render_to_string(UccChatWeb.SideNavView,
        "account_box_status_select.html", account: account)
    Query.update(socket, :replaceWith, set: html, on: ".status-message-select")
  end

  defp show_status_message_select(socket) do
    async_js(socket, "$('.status-message-select').show(); $('.status-message-input').hide();")
    socket
  end

  defp show_status_message_input(socket) do
    async_js(socket, "$('.status-message-select').hide(); $('.status-message-input').show();")
    socket
  end

  defp broadcast_status_message(socket, username, message) do
    UccPubSub.broadcast "user:all", "status_message:update", %{username: username, message: message}
    socket
  end

  @doc """
  The user callback used to update status messages.

  This is a UccPubSub Callback.

  Note: This is run for all users in the system. It does not check to see if a user is
        subscribed or not. It should really to that.

  TBD: Implement a filter to only push out if the user is subscribed to this person.
  """
  def status_message_update("status_message:update", %{username: username, message: message}, socket) do
    Query.update socket, :text, set: message, on: ~s(.status-message[data-username="#{username}"])
  end

  # End of States messages implementation

  # TOOD: this needs to be moved like the video stuff
  def start_audio_call(socket, sender) do
    current_user_id = socket.assigns.user_id
    user_id = sender["dataset"]["id"]
    Logger.debug fn -> "start audio curr_id: #{current_user_id}, user_id: #{user_id}" end
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

    do_room_update(socket, payload[:field], user_id, channel_id)
  end

  defp do_room_update(socket, {:name, new_room}, user_id, channel_id) do
    room = socket.assigns.room
    RoomChannel.broadcast_name_change(room, new_room, user_id, channel_id)
    # broadcast message header on room channel
    # broadcast room entry on user channel
    socket
  end

  defp do_room_update(socket, {:topic, data}, _user_id, _channel_id) do
    trace "do_room_update", {:topic, data}
    RoomChannel.broadcast_room_field(socket.assigns.room, "topic", data)
    socket
  end

  defp do_room_update(socket, {:description, data}, _user_id, _channel_id) do
    trace "do_room_update", {:description, data}
    RoomChannel.broadcast_room_field(socket.assigns.room, "description", data)
    socket
  end

  defp do_room_update(socket, {:type, type}, user_id, channel_id) do
    trace "do_room_update", {:type, type}
    # Logger.error "room: #{socket.assigns.room}, type: #{inspect type}"

    icon_name = ChannelService.get_icon(type)
    room_name = socket.assigns.room

    RoomChannel.broadcast_room_field room_name, "room-icon", icon_name
    RoomChannel.broadcast_message_box(socket.assigns.room, channel_id, user_id)

    set_room_icon(socket, room_name, icon_name)
  end

  defp do_room_update(socket, {:read_only, data}, user_id, channel_id) do
    trace "do_room_update", {:read_only, data}
    RoomChannel.broadcast_message_box(socket.assigns.room, channel_id, user_id)
  end

  defp do_room_update(socket, {:archived, value}, user_id, channel_id) do
    trace "do_room_update", {:archive, value}

    room_name = socket.assigns.room
    RoomChannel.broadcast_message_box(room_name, channel_id, user_id)
    update_room_visibility socket, channel_id, room_name, not value
  end

  defp do_room_update(socket, field, _user_id, _channel_id) do
    Logger.warn fn -> "Default case. Should not be called. field: " <>
      "#{inspect field}, assigns: #{inspect socket.assigns}" end
    socket
  end

  defp update_room_visibility(socket, channel_id, room_name, visible?) do
    [channel_id: channel_id]
    |> Subscription.list_by
    |> Enum.each(fn %{user_id: user_id} ->
      Logger.debug fn -> "broadcast update room room-visibility to user_id: #{inspect user_id}" end
      socket.endpoint.broadcast CC.chan_user <> user_id, "update:room-visibility",
        %{visible: visible?, room_name: room_name, user_id: user_id, channel_id: channel_id}
    end)
    socket
  end

  defp update_rooms_list(socket, user_id, channel_id) do
    trace "update_room_visibility", {user_id, channel_id}

    update socket, :html,
      set: SideNavService.render_rooms_list(channel_id, user_id),
      on: "aside.side-nav .rooms-list"
    socket
  end

  def webrtc_offer(event, payload, socket) do
    trace event, payload, inspect(socket.assigns)
    socket
  end

  # defp broadcast_rooms_list(socket, user_id, channel_id) do
  #   socket
  # end

  defp update_message_box(%{assigns: %{channel_id: channel_id}} = socket, user_id, channel_id) do
    update socket, :html,
      set: MessageService.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
    socket
  end

  defp update_message_box(socket, _user_id, _channel_id) do
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
    trace "video_stop", sender
    broadcast_js(socket, "window.WebRTC.hangup()")
    execute(socket, :click, on: ".tab-button.active")
  end

  @doc """
  Handle and event targeted to all users on the system.

  The event handles for a "user:all" event generated by the UcxPubSub system.
  This is a generic handler that simply runs the callback provided in the
  payload map. The socket is provided to the callback so it can use Rebel
  perform updates on the client side.

  This event handler allows decoupled access to the client from any plugin.
  """
  def user_all_event("callback" = evt, %{callback: callback, payload: payload}, socket) do
    callback.(evt, payload, socket)
  end

  def click_status(socket, sender) do
    # Logger.error "Click Status #{inspect sender}"
    user_id = socket.assigns.user_id
    status = sender["dataset"]["status"] || ""
    # Logger.error "handle status #{status}"
    UccPubSub.broadcast "status:" <> user_id, "set:" <> status, sender["dataset"]
    execute socket, :click, on: ".account-box.active"
  end

  def phone_call(socket, sender) do
    # Logger.warn "click to call... #{inspect sender}"
    username = sender["dataset"]["phoneStatus"]
    # TODO: Need to use a unique Id here instead of the userkame
    UccPubSub.broadcast "user:" <> socket.assigns.user_id, "phone:call",
      %{username: username}
    socket
  end

  def remove_user(socket, %{} = sender) do
    remove_user socket, sender["dataset"]["id"]
  end

  def remove_user(socket, user_id) do
    current_user = Accounts.get_user socket.assigns.user_id, preload: [:roles, user_roles: :role]
    user = Accounts.get_user user_id
    channel = Channel.get socket.assigns.channel_id
    case WebChannel.remove_user channel, user.id, current_user do
      {:ok, _message} ->
        js = """
          var user_view = $('.user-view[data-username="#{user.username}"]');
          if (!user_view.hasClass('animated-hidden')) {
            user_view.find('.button.back').click();
          }
        """
        |> String.replace("\n", "")

        socket.endpoint.broadcast CC.chan_room <> channel.name,
          "update:remove_user", %{username: user.username, js: js}
        Client.toastr! socket, :success, ~g(User removed)
      {:error, message} ->
        Client.toastr! socket, :error, message
    end
  end

  def mousedown(socket, _sender) do
    # Logger.debug "mousedown sender: #{inspect sender}"
    socket
  end

  def delegate(socket, sender) do
    # Logger.warn "delegate sender: #{inspect sender}"
    dataset = sender["dataset"]
    mod =  Module.concat(dataset["module"], nil)
    fun = String.to_existing_atom dataset["fun"]
    apply mod, fun, [socket, sender]
  end

  def phone_number(socket, sender, client \\ UccChatWeb.Client) do
    # Logger.warn "phone_number sender: #{inspect sender}"
    unless sender["html"] =~ "phone-cog" do
      html = Phoenix.View.render_to_string FlexBarView, "phone_cog.html",
        phone: sender["dataset"]["phone"]
      # Logger.warn "phone_number html: #{inspect html}"
      client.append(socket, this(sender), html)
    end

    socket
  end

  # def toggle_webrtc_enabled(socket, sender) do
  #   user = Accounts.get_user socket.assigns.user_id
  #   # form = sender["form"]
  #   id = "#" <> sender["dataset"]["id"]

  #   start_loading_animation(socket, id)

  #   val = !Rebel.Query.select(socket, prop: "checked", from: id)

  #   with {:ok, user} <- Accounts.update_user(user, %{webrtc_enabled: val}),
  #        client <- Mscs.Client.get(user.id),
  #        true <- is_nil(client.mac) and val,
  #        {:ok, _client} <- Mscs.Client.add_mac_address!(client) do
  #     handle_webrtc_enabled_success(socket, val, id)
  #   else
  #     false ->
  #       handle_webrtc_enabled_success(socket, val, id)
  #     {:error, _} ->
  #       Client.toastr! socket, :error, ~g(Problem updating WebRTC mode)
  #   end
  #   |> stop_loading_animation()
  # end

  # # TODO: Don't think we need this
  # def toggle_webrtc_enabled_change(socket, sender) do
  #   Logger.warn inspect(sender)
  #   socket
  # end

  # defp handle_webrtc_enabled_success(socket, val, id) do
  #   Rebel.Query.update socket, prop: "checked", set: val, on: id
  #   msg =
  #     if val do
  #       # UcxUcc.TabBar.show_button("mscs")
  #       ~g(WebRTC Enabled!)
  #     else
  #       # UcxUcc.TabBar.hide_button("mscs")
  #       ~g(WebRTC Disabled!)
  #     end

  #   socket
  #   |> UccUiFlexTab.FlexTabChannel.refresh_tab_bar
  #   |> Client.toastr!(:success, msg)
  # end

  def close_phone_cog(socket, sender, client \\ UccChatWeb.Client) do
    # Logger.warn "close_phone_cog sender: #{inspect sender}"
    client.remove_closest socket, this(sender), "a.phone-number", ".phone-cog"
  end

  def add_phone_number(socket, sender, client \\ UccChatWeb.Client) do
    user_id = sender["dataset"]["userId"]
    html = Phoenix.View.render_to_string FlexBarView, "new_phone_number.html", user: %{id: user_id}
    client.html socket, "fieldset.phone-numbers", html
    socket
  end

  def delete_phone_number(socket, sender, client \\ UccChatWeb.Client) do
    user_id = sender["form"]["user[id]"]
    html = Phoenix.View.render_to_string FlexBarView, "add_phone_number_button.html", user: %{id: user_id}
    client.html socket, "fieldset.phone-numbers", html
    socket
  end

  defdelegate flex_tab_click(socket, sender), to: FlexTabChannel
  defdelegate flex_tab_open(socket, sender), to: FlexTabChannel
  defdelegate flex_call(socket, sender), to: FlexTabChannel
  defdelegate flex_close(socket, sender), to: FlexTabChannel
  defdelegate flex_form(socket, sender), to: Form
  defdelegate flex_form_change(socket, sender), to: Form
  defdelegate flex_form_save(socket, sender), to: Form
  defdelegate flex_form_submit(socket, sender), to: Form
  defdelegate flex_form_cancel(socket, sender), to: Form
  defdelegate flex_form_toggle(socket, sender), to: Form
  defdelegate flex_form_select_change(socket, sender), to: Form

  # TODO: Figure out a way to inject this from the Dialer module
  defdelegate dial(socket, sender), to: UccDialerWeb.Channel.Dialer

  # defdelegate click_admin(socket, sender), to: UccAdminWeb.AdminChannel

  defdelegateadmin :click_admin
  defdelegateadmin :admin_link
  defdelegateadmin :admin_flex

end
