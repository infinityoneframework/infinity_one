defmodule UccAdmin.Web.Router do
  use UccAdmin.Web, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", UccAdmin.Web do
  #   pipe_through :protected # Use the default browser stack

  #   get "/", PageController, :index
  # end

  scope "/", UccAdmin.Web do
    pipe_through :protected # Use the default browser stack
    get "/", AdminController, :info
    get "/:page", AdminController, :index
  end
end
