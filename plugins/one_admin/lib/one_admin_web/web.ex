defmodule OneAdminWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use OneAdminWeb, :controller
      use OneAdminWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: OneAdminWeb
      import Plug.Conn
      # import OneAdminWeb.Router.Helpers
      use InfinityOneWeb.Gettext
      alias InfinityOne.Repo
      import Ecto.Query
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "plugins/one_admin/lib/one_admin_web/templates",
                        namespace: OneAdminWeb

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      use InfinityOneWeb.Gettext

      # import OneAdminWeb.Router.Helpers
      import OneAdminWeb.ErrorHelpers
      import OneChatWeb.SharedView
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      alias InfinityOne.Permissions
      alias InfinityOne.Accounts.User
      alias InfinityOne.Repo

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
      use InfinityOneWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
