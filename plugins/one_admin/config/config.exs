use Mix.Config

config :unbrella, :plugins, one_admin: [
  module: OneAdmin,
  application: OneAdmin.Application,
  # router: OneAdminWeb.Router,
]
