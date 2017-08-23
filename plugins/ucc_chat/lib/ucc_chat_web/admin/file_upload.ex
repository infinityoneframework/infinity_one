defmodule UccChatWeb.Admin.Page.FileUpload do
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks}
  alias UccChat.Settings.FileUpload

  def add_page do
    new(
      "admin_file_upload",
      __MODULE__,
      ~g(FileUpload),
      UccChatWeb.AdminView,
      "file_upload.html",
      80,
      [pre_render_check: &UccChatWeb.Admin.view_message_admin_permission?/2]
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: FileUpload.get |> FileUpload.changeset,
    ], user, page, socket}
  end

end
