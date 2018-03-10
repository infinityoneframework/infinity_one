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
      pre_render_check: &check_perissions/2,
      permission: "view-file-upload-administration"
    )
  end

  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: FileUpload.get |> FileUpload.changeset,
    ], user, page, socket}
  end

  def check_perissions(_page, user) do
    has_permission? user, "view-file-upload-administration"
  end
end
