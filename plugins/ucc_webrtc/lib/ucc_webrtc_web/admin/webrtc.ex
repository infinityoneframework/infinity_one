defmodule UccWebrtcWeb.Admin.Page.Webrtc do
  use UccAdmin.Page

  import UcxUccWeb.Gettext

  alias UcxUcc.{Repo, Hooks}
  alias UccWebrtc.Settings.Webrtc

  def add_page do
    new("admin_webrtc", __MODULE__, ~g(WebRTC), UccWebrtcWeb.AdminView, "webrtc.html", 90)
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Webrtc.get |> Webrtc.changeset,
    ], user, page, socket}
  end

end
