use Mix.Config

config :unbrella, :plugins, ucc_admin: [
  module: UccAdmin,
  router: UccAdmin.Web.Router,
]
