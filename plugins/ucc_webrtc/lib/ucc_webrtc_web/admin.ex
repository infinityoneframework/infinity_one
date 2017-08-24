defmodule UccWebrtcWeb.Admin do

  alias UccWebrtcWeb.Admin.Page.Webrtc

  def add_pages(list) do
    [Webrtc.add_page | list]
  end

end
