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

if File.exists? "config/test.secret.exs" do
  import_config "prod.secret.exs"
end
