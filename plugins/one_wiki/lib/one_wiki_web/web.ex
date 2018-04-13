defmodule OneWikiWeb do

  def view do
    quote do
      use Phoenix.View, root: "plugins/one_wiki/lib/one_wiki_web/templates",
                        namespace: OneWikiWeb
      use Phoenix.HTML
      use InfinityOneWeb.Gettext

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1], warn: false

      # Use all HTML functionality (forms, tags, etc)
      import InfinityOneWeb.ErrorHelpers, warn: false
      import OneChatWeb.SharedView, warn: false
      import InfinityOneWeb.Utils, warn: false
      alias InfinityOne.Permissions, warn: false

      require Logger
    end
  end

  def channel do
    quote do
      use InfinityOneWeb.Gettext
      import InfinityOneWeb.{Channel}, warn: false
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
