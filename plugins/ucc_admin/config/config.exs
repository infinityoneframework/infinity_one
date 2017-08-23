use Mix.Config

config :unbrella, :plugins, ucc_admin: [
  module: UccAdmin,
  application: UccAdmin.Application,
  # router: UccAdminWeb.Router,
]
