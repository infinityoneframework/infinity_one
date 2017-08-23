defmodule UccChatWeb.Admin.Page.ChatGeneral do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks}
  alias UccChat.Settings.ChatGeneral

  def add_page do
    new(
      "admin_chat_general",
      __MODULE__,
      ~g(Chat General),
      UccChatWeb.AdminView,
      "chat_general.html",
      65,
      [pre_render_check: &UccChatWeb.Admin.view_message_admin_permission?/2]
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: ChatGeneral.get |> ChatGeneral.changeset,
    ], user, page, socket}
  end

end
