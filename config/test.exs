use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ucx_ucc, UcxUcc.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :ucx_ucc, UcxUcc.Web.Endpoint,
  secret_key_base: "Z9j5A+lDlf1qG+i2ZhVavb0GKHDLkZb/MH7qVy95FM8s2T0d3AI7WU6gyWipUxVl"

# Configure your database
config :ucx_ucc, UcxUcc.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "Gt5de3aq1",
  database: "ucx_ucc_prod",
  pool_size: 15
