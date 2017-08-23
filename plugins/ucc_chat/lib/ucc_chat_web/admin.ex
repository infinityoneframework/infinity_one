defmodule UccChatWeb.Admin do
  import UcxUccWeb.Gettext
  alias Phoenix.HTML.Tag

  @pages [
    Info, Rooms, Users, Permissions, Search, General, ChatGeneral,
    Message, Layout, FileUpload
  ] |> Enum.map(&Module.concat([__MODULE__, Page, &1]))

  def add_pages(list) do
    settings = UccAdmin.Page.new [
      id: "admin_settings",
      name: ~g(Settings),
      order: 45,
      opts: [
        render_link: fn _, _ ->
          Tag.content_tag :h3, [class: "add-room"], do: ~g(Settings)
        end
      ]
    ]
    Enum.map(@pages, &apply(&1, :add_page, [])) ++ [settings | list]
  end

  def view_message_admin_permission?(_, user, scope \\ nil) do
    UcxUcc.Permissions.has_permission? user, "view-message-administration", scope
  end
end
