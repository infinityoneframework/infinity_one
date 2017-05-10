defmodule UcxUcc.Web.LayoutView do
  use UcxUcc.Web, :view

  # TODO: This does not belog here. Need a generic approach here
  def site_title do
    UccChat.Settings.site_name()
  end
  
  # TODO: same as the previous comment
  def audio_files do
    ~w(chime beep chelle ding droplet highbell seasons door)
    |> Enum.map(&({&1, "/sounds/#{&1}.mp3"}))
  end
end
