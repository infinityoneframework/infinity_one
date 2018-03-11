defmodule OneWebrtcWeb.Admin.Page.Webrtc do
  use OneAdmin.Page

  import InfinityOneWeb.Gettext

  alias InfinityOne.{Repo, Hooks}
  alias OneWebrtc.Settings.Webrtc

  def add_page do
    new(
      "admin_webrtc",
      __MODULE__,
      ~g(WebRTC),
      OneWebrtcWeb.AdminView,
      "webrtc.html",
      90,
      pre_render_check: &check_perissions/2,
      permission: "view-webrtc-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Webrtc.get |> Webrtc.changeset,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-webrtc-administration"
  end
end
