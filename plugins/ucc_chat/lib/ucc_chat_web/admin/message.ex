defmodule UccChatWeb.Admin.Page.Message do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks}
  alias UccChat.Settings.Message

  def add_page do
    new(
      "admin_message",
      __MODULE__,
      ~g(Message),
      UccChatWeb.AdminView,
      "message.html",
      70,
      [pre_render_check: &UccChatWeb.Admin.view_message_admin_permission?/2]
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Message.get |> Message.changeset,
    ], user, page, socket}
  end

end
