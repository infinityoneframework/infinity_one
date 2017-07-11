defmodule UccChat.Web.Router do
  use UccChat.Web, :router
  use Coherence.Router

  IO.inspect "Compiling router"

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  IO.inspect "Compiling router 2"

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  IO.inspect "Compiling router 3"
  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UccChat.Web do
    pipe_through :protected

    get "/avatar/:username", AvatarController, :show
    get "/", HomeController, :index
    get "/home", HomeController, :index
    get "/channels/:name", ChannelController, :show
    get "/direct/:name", ChannelController, :direct
    get "/switch_user/:user", PageController, :switch_user
    # resources "/channel", ChannelController
  end

  IO.inspect "Compiling router 4"
  scope "/", UccChat.Web do
    pipe_through :api
    post "/attachments/create", AttachmentController, :create
  end
  IO.inspect "Compiling router 5"
end
