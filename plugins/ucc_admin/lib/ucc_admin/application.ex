defmodule UccAdmin.Application do

  def start(_, _) do
    UccAdmin.initialize

    []
    |> UcxUcc.Hooks.register_admin_pages
    |> Enum.map(fn
      pages when is_list(pages) ->
        Enum.map pages, &UccAdmin.add_page/1
      page ->
        UccAdmin.add_page page
    end)
  end

end
