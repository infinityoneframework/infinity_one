defmodule OneChatWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use OneChatWeb, :controller
      use OneChatWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """


  def controller do
    quote do
      Code.ensure_compiled(OneChatWeb.Router)
      use Phoenix.Controller, namespace: OneChatWeb
      use InfinityOneWeb.Gettext

      import Plug.Conn
      import OneChatWeb.Router.Helpers
      import Ecto.Query

      alias InfinityOne.Repo
      # import OneChatWeb.Gettext
    end
  end

  def channel_controller do
    quote do
      use InfinityOne.Utils
      use InfinityOneWeb.Gettext

      import Ecto
      import Ecto.Query
      import InfinityOneWeb.Utils, warn: false

      alias InfinityOne.Repo
    end
  end

  def view do
    quote do
      Code.ensure_compiled(OneChatWeb.Router)
      use Phoenix.View, root: "plugins/one_chat/lib/one_chat_web/templates",
                        namespace: OneChatWeb
      use Phoenix.HTML
      use InfinityOneWeb.Gettext

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      import OneChatWeb.Router.Helpers
      import OneChatWeb.ErrorHelpers
      import OneChatWeb.SharedView
      import InfinityOneWeb.Utils, warn: false
      # import OneChatWeb.Gettext
      alias InfinityOne.Accounts.User
      alias InfinityOne.Repo
      alias InfinityOne.Permissions

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
      # use Phoenix.Channel
      use InfinityOneWeb.Gettext

      import InfinityOneWeb.{Channel}, warn: false

    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
