use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ucx_ucc, UcxUcc.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Finally import the config/test.secret.exs
# which should be versioned separately.
import_config "test.secret.exs"