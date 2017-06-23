defmodule UccChat.Web.LayoutView do
  use UccChat.Web, :view

  def audio_files do
    ~w(chime beep chelle ding droplet highbell seasons door)
    |> Enum.map(&({&1, "/sounds/#{&1}.mp3"}))
  end

  def site_title do
    UccSettings.site_name()
  end
end
