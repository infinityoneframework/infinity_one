defmodule UcxUcc.Web.LayoutView do
  use UcxUcc.Web, :view

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
    channel_id = conn.assigns.chatd.active_room.channel_id
    token = Coherence.user_token(conn)
    user_id = Coherence.current_user(conn) |> Map.get(:id)

    Rebel.Client.js conn,
      user_id: user_id,
      conn_opts: [
        tz_offset: "new Date().getTimezoneOffset() / -60",
        channel_id: ~s("#{channel_id}"),
        token: ~s("#{token}")
      ]

  end
end
