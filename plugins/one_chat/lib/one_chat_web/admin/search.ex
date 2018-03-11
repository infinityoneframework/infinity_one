defmodule OneChatWeb.Admin.Page.Search do
  use OneAdmin.Page
  alias Phoenix.HTML.Tag

  # import Ecto.Query

  # alias InfinityOne.{Repo, Hooks, Accounts, Permissions}
  # alias Accounts.{User, Role}

  def add_page do
    new(
      "admin_search",
      __MODULE__,
      "",
      OneChatWeb.AdminView,
      "",
      50,
      [
        render_link: fn _, _ ->
          Tag.content_tag :li do
            Tag.tag :input, type: :text, name: "admin-settings-search", placeholder: ~g(Search)
          end
        end
      ]
    )
  end

end
