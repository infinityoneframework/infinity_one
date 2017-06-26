use Mix.Config

config :ucc_admin, :talon,
  module: UccAdmin,
  themes: ["admin-lte"],
  concerns: [UccAdmin.Admin],

  web_namespace: Web


config :ucc_admin, UccAdmin.Admin,
  resources: [
  ],
  pages: [
    UccAdmin.Admin.Info
  ],
  theme: "admin-lte",
  root_path: "lib/ucc_admin/talon",
  path_prefix: "",
  repo: UccAdmin.Repo,
  router: UccAdmin.Web.Router,
  endpoint: UccAdmin.Web.Endpoint,
  schema_adapter: Talon.Schema.Adapters.Ecto,
  messages_backend: UccAdmin.Talon.Messages


