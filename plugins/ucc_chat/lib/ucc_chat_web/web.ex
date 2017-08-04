defmodule UccChatWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use UccChatWeb, :controller
      use UccChatWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """


  def controller do
    quote do
      Code.ensure_compiled(UccChatWeb.Router)
      use Phoenix.Controller, namespace: UccChatWeb
      import Plug.Conn
      import UccChatWeb.Router.Helpers
      use UcxUccWeb.Gettext
      alias UcxUcc.Repo
      import Ecto.Query
      # import UccChatWeb.Gettext
    end
  end

  def channel_controller do
    quote do
      alias UcxUcc.Repo
      import Ecto
      import Ecto.Query
      use UcxUcc.Utils
      use UcxUccWeb.Gettext
    end
  end

  def view do
    quote do
      Code.ensure_compiled(UccChatWeb.Router)
      use Phoenix.View, root: "plugins/ucc_chat/lib/ucc_chat_web/templates",
                        namespace: UccChatWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import UccChatWeb.Router.Helpers
      import UccChatWeb.ErrorHelpers
      # import UccChatWeb.Gettext
      use UcxUccWeb.Gettext
      alias UcxUcc.Accounts.User
      alias UcxUcc.Repo
      import UccChatWeb.SharedView
      alias UcxUcc.Permissions
      require Logger
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      # import UccChatWeb.Gettext
      use UcxUccWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
