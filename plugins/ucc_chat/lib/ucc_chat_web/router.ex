defmodule UccChatWeb.Router do
  use UccChatWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug UcxUcc.Plugs.Setup
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug UcxUcc.Plugs.Setup
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UcxUccWeb  do
    pipe_through :browser
    coherence_routes()
  end

  scope "/", UcxUccWeb  do
    pipe_through :protected

    get "/landing", LandingController, :index
    get "/logout", Coherence.SessionController, :delete
    coherence_routes :protected
  end

  scope "/", UccChatWeb do
    pipe_through :protected

    get "/", HomeController, :index
    get "/home", ChannelController, :page
    get "/channels/:name", ChannelController, :show
    get "/direct/:name", ChannelController, :direct
    get "/switch_user/:user", PageController, :switch_user
    # resources "/channel", ChannelController
  end

  scope "/", UccChatWeb do
    pipe_through :api
    post "/attachments/create", AttachmentController, :create
  end
end
