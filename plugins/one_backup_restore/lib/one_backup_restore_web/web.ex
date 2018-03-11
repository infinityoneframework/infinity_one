defmodule OneBackupRestoreWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use OneBackupRestoreWeb, :controller
      use OneBackupRestoreWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: OneBackupRestoreWeb
      use InfinityOneWeb.Gettext
      import Plug.Conn
      import InfinityOneWeb.Router.Helpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "plugins/one_backup_restore/lib/one_backup_restore_web/templates",
                        namespace: OneBackupRestoreWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      use InfinityOneWeb.Gettext

      # import OneBackupRestoreWeb.Router.Helpers
    end
  end

  # def router do
  #   quote do
  #     use Phoenix.Router
  #     import Plug.Conn
  #     import Phoenix.Controller
  #   end
  # end

  # def channel do
  #   quote do
  #     use Phoenix.Channel
  #     use InfinityOneWeb.Gettext
  #   end
  # end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
