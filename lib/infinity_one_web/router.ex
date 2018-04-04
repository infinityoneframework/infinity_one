defmodule InfinityOneWeb.Router do
  use InfinityOneWeb, :router
  use OnePagesWeb.Router
  use Coherence.Router

  pipeline :browser do
    plug(:accepts, ["html", "md"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(InfinityOne.Plugs.Setup)
    plug(Coherence.Authentication.Session)
  end

  pipeline :protected do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(InfinityOne.Plugs.Setup)
    plug(Coherence.Authentication.Session, protected: true)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", InfinityOneWeb do
    pipe_through(:browser)
    get("/landing", LandingController, :index)
    # get("/help", HelpController, :index)
    # get("/help/:id", HelpController, :show)
    coherence_routes()
  end

  scope "/", OnePagesWeb do
    pipe_through :browser

    one_pages_routes()
  end

  scope "/", InfinityOneWeb do
    pipe_through(:protected)

    get("/logout", Coherence.SessionController, :delete)
    coherence_routes(:protected)
  end

  scope "/", OneChatWeb do
    # Use the default browser stack
    pipe_through(:protected)

    get("/", ChannelController, :page)
    get("/phone", MasterController, :phone)
  end

  scope "/", OneBackupRestoreWeb do
    pipe_through(:protected)

    post("/upload_backup", UploadController, :create)
  end

  # The following is a prototype of an API implementation. It is basically
  # working, without authentication. Need updates in Coherence to get it
  # working
  scope "/api/v1", InfinityOneWeb.API do
    pipe_through(:api)
    # post "/login", SessionController, :create
    get("/server_settings", PublicController, :server_settings)
  end

  # forward "/admin", OneAdminWeb.Router
  # TODO: get unbrella working for this
  # forward "/client", MscsWeb.Router
  # forward "/", OneChatWeb.Router

  use Unbrella.Plugin.Router
  # Other scopes may use custom stacks.
  # scope "/api", InfinityOneWeb do
  #   pipe_through :api
  # enM k
end
