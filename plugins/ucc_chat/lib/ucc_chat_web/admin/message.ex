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
      pre_render_check: &check_perissions/2,
      permission: "view-message-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: Message.get |> Message.changeset,
      message_opts: UccChatWeb.MessageView.message_opts()
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-message-administration"
  end
end
