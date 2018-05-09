use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :infinity_one, InfinityOneWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :error
config :logger, :console,
  level: :error,
  # level: :error,
  format: "\n$time [$level]$levelpad$metadata$message\n",
  metadata: [:module, :function, :line]

# config :infinity_one, InfinityOne.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "infinity_one_test3",
#   hostname: "localhost",
#   pool: Ecto.Adapters.SQL.Sandbox

if File.exists? "config/test.secret.exs" do
  import_config "test.secret.exs"
end
