defmodule OneAdmin.Application do

  def start(_, _) do
    OneAdmin.initialize

    []
    |> InfinityOne.Hooks.register_admin_pages
    |> Enum.map(fn
      pages when is_list(pages) ->
        Enum.map pages, &OneAdmin.add_page/1
      page ->
        OneAdmin.add_page page
    end)
  end

end
