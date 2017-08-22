defmodule UccWebrtcWeb.FlexBar.Tab.MembersList do
  use UccLogger

  import Rebel.{Core, Query}

  alias UcxUcc.Accounts
  alias UccWebrtcWeb.VideoView
  alias UccChatWeb.FlexBar.Tab.MembersList, as: ChatMembersList
  alias UccWebrtcWeb.FlexBar.Tab.MembersList
  alias UcxUcc.TabBar
  alias UcxUcc.TabBar.Ftab

  require UccChat.ChatConstants, as: CC
  require Logger

  def video_args(socket, current_user_id, _channel_id, user_id) do
    username = socket.assigns.username
    other_user = Accounts.get_user user_id
    Logger.warn "video args curr_id: #{current_user_id}, user_id: #{user_id}"
    # remote_item = %{connected: false, state_text: "state", id: other_user.id,
    #   username: other_user.username}

    {[webrtc: %{self: username,
      id: 1,
      audio_and_video_enabled: true,
      video_available: true,
      video_active: true,
      video_enabled: true,
      audio_enabled: true,
      main_video_url: "none",
      self_video_url: "other",
      main_video_username: username,
      other_video_username: other_user.username,
      remote_video_items: [],
      screen_share_available: false,
      screen_share_enabled: false,
      overlay_enabled: false,
      overlay: false
    }], socket}
  end

  def open(socket, current_user_id, channel_id, tab, args) do
    Logger.warn "open assigns: #{inspect socket.assigns}"
    user_id = args["user_id"]
    Logger.warn "stuff: #{inspect %{current_user_id: current_user_id, user_id: user_id, assigns_user_id: socket.assigns.user_id}}"
    {view_args, socket} = MembersList.video_args(socket,
      current_user_id, channel_id, user_id)
    Logger.warn "args: #{inspect view_args}"

    unless args[:dest] do
      socket.endpoint.broadcast "user:" <> user_id, "webrtc:incoming_video_call",
        %{from: socket.assigns.user_id,
          username: socket.assigns.username}
    end

    html = Phoenix.View.render_to_string VideoView, "show.html", view_args

    socket =
      socket
      |> ChatMembersList.open(user_id, channel_id, tab, nil)
      |> update(:class, toggle: "animated-hidden", on: ".flex-tab-container .user-view")
      |> insert(html, append: ".flex-tab .content")
    exec_js socket, "window.WebRTC.start();"
    socket
  end

  def video_stop(%{assigns: assigns} = socket, _sender) do
    TabBar.close_view assigns.user_id, assigns.channel_id, "members-list"

    socket.endpoint.broadcast CC.chan_webrtc <> "user-" <> socket.assigns.user_id,
      "webrtc:leave", %{}

    socket
    |> update(:class, toggle: "animated-hidden",
      on: ".flex-tab-container .user-view")
    |> delete(".flex-tab-container .webrtc-video")
  end

  def flex_video_open(socket, sender) do
    Logger.warn "flex_video_open, assigns: #{inspect socket.assigns}"
    channel_id = Rebel.get_assigns(socket, :channel_id)
    user_id = sender["dataset"]["user_id"]

    tab = TabBar.get_button "members-list"

    Ftab.open user_id, channel_id, "members-list", %{"view" => "video",
      "user_id" => user_id}, fn :open, {_, args} ->
        apply tab.module, :open, [socket, user_id, channel_id, tab, args]
      end
  end

  def open_destination_video(socket, current_user_id, user_id) do
    trace "", %{current_user_id: current_user_id, user_id: user_id}
    trace "assigns", socket.assigns
    _ = current_user_id

    # channel_id = Rebel.get_assigns(socket, :channel_id)
    channel_id = socket.assigns.channel_id
    trace "channel_id", channel_id

    tab = TabBar.get_button "members-list"

    Ftab.open user_id, channel_id, "members-list", %{"view" => "video",
      "user_id" => user_id}, fn :open, {_, args} ->
        Logger.error "args: #{inspect args}"
        apply tab.module, :open, [socket, user_id, channel_id, tab, Map.put(args, :dest, true)]
      end
  end
end
