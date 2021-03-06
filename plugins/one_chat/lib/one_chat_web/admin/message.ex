defmodule OneChatWeb.Admin.Page.Message do
  use OneAdmin.Page

  alias InfinityOne.{Repo, Hooks}
  alias OneChat.Settings.Message
  alias OneAdminWeb.View.Utils

  def add_page do
    new(
      "admin_message",
      __MODULE__,
      ~g(Message),
      OneChatWeb.AdminView,
      "message.html",
      70,
      pre_render_check: &check_perissions/2,
      permission: "view-message-administration"
    )
  end

  def args(page, user, _sender, socket) do
    message = Message.get()
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: message |> Message.changeset(),
      message_opts: OneChatWeb.MessageView.message_opts()
    ] ++ Utils.changed_bindings(Message, message), user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-message-administration"
  end
end
