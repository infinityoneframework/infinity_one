defmodule OneWebrtcWeb.Admin do

  alias OneWebrtcWeb.Admin.Page.Webrtc

  def add_pages(list) do
    [Webrtc.add_page | list]
  end

end
