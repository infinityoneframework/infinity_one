defmodule OneChatWeb.Router do
  use OneChatWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InfinityOne.Plugs.Setup
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InfinityOne.Plugs.Setup
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InfinityOneWeb  do
    pipe_through :browser
    coherence_routes()
  end

  scope "/", InfinityOneWeb  do
    pipe_through :protected

    get "/landing", LandingController, :index
    get "/logout", Coherence.SessionController, :delete
    coherence_routes :protected
  end

  scope "/", OneChatWeb do
    pipe_through :protected

    get "/", HomeController, :index
    get "/home", ChannelController, :page
    get "/channels/:name", ChannelController, :show
    get "/direct/:name", ChannelController, :direct
    get "/switch_user/:user", PageController, :switch_user
    # resources "/channel", ChannelController
  end

  # TODO: This is not authenticated. It needs to be fixed
  scope "/", OneChatWeb do
    pipe_through :api
    post "/attachments/create", AttachmentController, :create
    post "/avatars/create", AvatarController, :create
  end

  # The following is a prototype of an API implementation. It is basically
  # working, without authentication. Need updates in Coherence to get it
  # working
  # scope "/api/v1", OneChatWeb.API do
  #   pipe_through :api

  #   get "/channels/info/:name", ChannelController, :show
  #   post "/messages/post", MessageController, :create
  # end
end
