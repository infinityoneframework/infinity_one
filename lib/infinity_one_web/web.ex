defmodule InfinityOneWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use InfinityOneWeb, :controller
      use InfinityOneWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def root_url do
    InfinityOneWeb.Endpoint
    |> InfinityOneWeb.Router.Helpers.channel_url(:page)
    |> String.trim_trailing("/")
  end

  def service do
    quote do
      import Ecto.Query
      use InfinityOneWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: InfinityOneWeb
      import Plug.Conn
      import InfinityOneWeb.Router.Helpers
      use InfinityOneWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/infinity_one_web/templates",
        namespace: InfinityOneWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import OneChat.AvatarService, only: [avatar_url: 1]
      import InfinityOneWeb.Router.Helpers
      import InfinityOneWeb.ErrorHelpers
      use InfinityOneWeb.Gettext
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
      import InfinityOneWeb.Channel
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
