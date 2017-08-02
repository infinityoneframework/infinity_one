defmodule UccAdminWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use UccAdminWeb, :controller
      use UccAdminWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: UccAdminWeb
      import Plug.Conn
      # import UccAdminWeb.Router.Helpers
      use UcxUccWeb.Gettext
      alias UcxUcc.Repo
      import Ecto.Query
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "plugins/ucc_admin/lib/ucc_admin/web/templates",
                        namespace: UccAdminWeb

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      use UcxUccWeb.Gettext

      # import UccAdminWeb.Router.Helpers
      import UccAdminWeb.ErrorHelpers
      import UccChatWeb.SharedView
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      alias UcxUcc.Permissions
      alias UcxUcc.Accounts.User
      alias UcxUcc.Repo

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
