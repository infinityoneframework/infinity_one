defmodule UcxUcc.Web.Router do
  use UcxUcc.Web, :router
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

  scope "/", UcxUcc.Web  do
    pipe_through :browser
    coherence_routes()
  end

  scope "/", UcxUcc.Web  do
    pipe_through :protected
    coherence_routes :protected
  end


  scope "/", UccChat.Web do
    pipe_through :protected # Use the default browser stack

    get "/", HomeController, :index
    get "/phone", MasterController, :phone
  end

  # forward "/admin", UccAdmin.Web.Router
  forward "/", UccChat.Web.Router

  # use Unbrella.Plugin.Router
  # Other scopes may use custom stacks.
  # scope "/api", UcxUcc.Web do
  #   pipe_through :api
  # end
end
