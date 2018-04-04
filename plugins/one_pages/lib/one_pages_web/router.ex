defmodule OnePagesWeb.Router do
  # use OneChatWeb, :router
  use OnePagesWeb, :router
  # use Coherence.Router

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [one_pages_routes: 0]
    end
  end

  defmacro one_pages_routes do
    quote do
      get "/pages", PageController, :index
      get "/apps/:id", AppsController, :show
      get "/apps", AppsController, :index
      get "/features", FeaturesController, :index
      get "/why", WhyController, :index
      get "/help", HelpController, :index
      get "/help/:id", HelpController, :show
    end
  end

  # pipeline :browser do
  #   plug :accepts, ["html", "json"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  #   plug InfinityOne.Plugs.Setup
  #   plug Coherence.Authentication.Session
  # end

  # scope "/", InfinityOneWeb  do
  #   pipe_through :browser
  #   coherence_routes()
  # end

  # scope "/", OnePagesWeb  do
  #   pipe_through :browser

  #   get "/pages", PageController, :index
  #   get "/apps/:id", AppsController, :show
  #   get "/apps", AppsController, :index
  #   get "/features", FeaturesController, :index
  #   get "/why", WhyController, :index
  #   get "/help", HelpController, :index
  #   get "/help/:id", HelpController, :show
  # end
end
