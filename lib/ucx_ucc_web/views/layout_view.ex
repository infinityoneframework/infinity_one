defmodule UcxUccWeb.LayoutView do
  use UcxUccWeb, :view
  use Bitwise

  require Logger

  # TODO: This does not belog here. Need a generic approach here
  def site_title do
    # UccChat.Settings.site_name()
    UccSettings.site_name()
  end

  # TODO: same as the previous comment
  def audio_files do
    ~w(chime beep chelle ding droplet highbell seasons door)
    |> Enum.map(&({&1, "/sounds/#{&1}.mp3"}))
  end

  def client_js(conn) do
    channel_id =
      try do
        conn.assigns.chatd.active_room.channel_id
      rescue
        _ ->
          ""
      end

    token = Coherence.user_token(conn)
    user_id = Coherence.current_user(conn) |> Map.get(:id)
    ip_address = get_ipaddress conn

    Rebel.Client.js conn,
      user_id: user_id,
      conn_opts: [
        tz_offset: "new Date().getTimezoneOffset() / -60",
        channel_id: ~s("#{channel_id}"),
        token: ~s("#{token}"),
        ip_address: ~s("#{ip_address}")
      ]

  end

  def get_ipaddress(conn) do
    {{a, b, c, d}, _} = conn.peer
    (a <<< 24) + (b <<< 16) + (c <<< 8) + d
  end

  def get_js_plugins do
    :ucx_ucc
    |> Application.get_env(:js_plugins, [])
    |> inspect
    |> String.replace(~s("), "'")
    |> Phoenix.HTML.raw
  end
end
