use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ucx_ucc, UcxUccWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :error
config :logger, :console,
  level: :error,
  # level: :error,
  format: "\n$time [$level]$levelpad$metadata$message\n",
  metadata: [:module, :function, :line]

config :ucx_ucc, UcxUcc.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ucx_ucc_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
