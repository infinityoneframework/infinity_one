defmodule UccWebrtcWeb.Admin do
  import UcxUccWeb.Gettext

  alias UccWebrtcWeb.Admin.Page.Webrtc

  def add_pages(list) do
    [Webrtc.add_page | list]
  end

end
